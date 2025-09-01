// import 'dart:developer';
// import 'dart:math' hide log;

// import 'package:delloniweb/controllers/debug_helper.dart';
// import 'package:delloniweb/screens/create_categories_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:typed_data';
// class AdminDataProvider with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   // Loading states with granular control
//   bool _isLoading = false;
//   bool _isDashboardLoading = false;
//   bool _isAnalyticsLoading = false;
//   String? _error;
//   DateTime? _lastUpdated;

//   // Basic Dashboard Data
//   int _totalUsers = 0;
//   int _totalProducts = 0;
//   int _totalOrders = 0;
//   int _totalRevenue = 0;
//   int _activeChats = 0;
//   int _pendingSupportRequests = 0;

//   // Enhanced Analytics Data
//   int _todayNewUsers = 0;
//   int _todayNewProducts = 0;
//   int _newUsersThisWeek = 0;
//   int _newListingsThisWeek = 0;
//   int _monthlyRevenue = 0;
//   int _averageResponseTime = 5;

//   // Growth percentages and trends
//   double _userGrowthPercentage = 0.0;
//   double _listingGrowthPercentage = 0.0;
//   double _revenueGrowthPercentage = 0.0;
//   double _chatGrowthPercentage = 0.0;
//   String _userTrend = 'up';
//   String _listingTrend = 'up';
//   String _revenueTrend = 'up';
//   String _chatTrend = 'up';

//   // Analytics collections
//   List<Map<String, dynamic>> _topSearches = [];
//   List<Map<String, dynamic>> _categoryTrends = [];
//   List<Map<String, dynamic>> _locationData = [];
//   List<Map<String, dynamic>> _topCities = [];
//   List<Map<String, dynamic>> _topUsers = [];
//   List<Map<String, dynamic>> _recentActivity = [];

//   // Core data collections
//   List<Map<String, dynamic>> _recentUsers = [];
//   List<Map<String, dynamic>> _recentProducts = [];
//   List<Map<String, dynamic>> _supportRequests = [];
//   List<Map<String, dynamic>> _allUsers = [];
//   List<Map<String, dynamic>> _allProducts = [];
//   List<Map<String, dynamic>> _allBanners = [];
//   List<Map<String, dynamic>> _chatConversations = [];
//   List<Map<String, dynamic>> _allCategories = [];
//    // NEW: Separate lists for different report types
//   List<Map<String, dynamic>> _allChatReports = [];
//   List<Map<String, dynamic>> _allAccountReports = [];

//   // NEW: Getters for different report types
//   List<Map<String, dynamic>> get allChatReports => _allChatReports;
//   List<Map<String, dynamic>> get allAccountReports => _allAccountReports;
  
//   // Keep existing getter for backward compatibility
//   List<Map<String, dynamic>> get allReports => [..._allChatReports, ..._allAccountReports];


//   // Template management properties
//   List<Map<String, dynamic>> _allTemplates = [];
//   List<Map<String, dynamic>> get allTemplates => _allTemplates;


//   // Caching system
//   final Map<String, List<Map<String, dynamic>>> _categoryCache = {};
//   final Map<String, dynamic> _analyticsCache = {};
//   static const Duration _cacheTimeout = Duration(minutes: 10);
//   DateTime? _lastCacheUpdate;

//   // Getters - Basic Data
//   bool get isLoading => _isLoading;
//   bool get isDashboardLoading => _isDashboardLoading;
//   bool get isAnalyticsLoading => _isAnalyticsLoading;
//   String? get error => _error;
//   DateTime? get lastUpdated => _lastUpdated;

//   // Basic stats
//   int get totalUsers => _totalUsers;
//   int get totalProducts => _totalProducts;
//   int get totalOrders => _totalOrders;
//   int get totalRevenue => _totalRevenue;
//   int get activeChats => _activeChats;
//   int get pendingSupportRequests => _pendingSupportRequests;

//   // Enhanced analytics getters
//   int get todayNewUsers => _todayNewUsers;
//   int get todayNewProducts => _todayNewProducts;
//   int get newUsersThisWeek => _newUsersThisWeek;
//   int get newListingsThisWeek => _newListingsThisWeek;
//   int get monthlyRevenue => _monthlyRevenue;
//   int get averageResponseTime => _averageResponseTime;

//   // Growth metrics
//   double get userGrowthPercentage => _userGrowthPercentage;
//   double get listingGrowthPercentage => _listingGrowthPercentage;
//   double get revenueGrowthPercentage => _revenueGrowthPercentage;
//   double get chatGrowthPercentage => _chatGrowthPercentage;
//   String get userTrend => _userTrend;
//   String get listingTrend => _listingTrend;
//   String get revenueTrend => _revenueTrend;
//   String get chatTrend => _chatTrend;

//   // Analytics collections
//   List<Map<String, dynamic>> get topSearches => _topSearches;
//   List<Map<String, dynamic>> get categoryTrends => _categoryTrends;
//   List<Map<String, dynamic>> get locationData => _locationData;
//   List<Map<String, dynamic>> get topCities => _topCities;
//   List<Map<String, dynamic>> get topUsers => _topUsers;
//   List<Map<String, dynamic>> get recentActivity => _recentActivity;

//   // Core data
//   List<Map<String, dynamic>> get recentUsers => _recentUsers;
//   List<Map<String, dynamic>> get recentProducts => _recentProducts;
//   List<Map<String, dynamic>> get supportRequests => _supportRequests;
//   List<Map<String, dynamic>> get allUsers => _allUsers;
//   List<Map<String, dynamic>> get allProducts => _allProducts;
//   List<Map<String, dynamic>> get allBanners => _allBanners;
//   List<Map<String, dynamic>> get chatConversations => _chatConversations;
//   List<Map<String, dynamic>> get allCategories => _allCategories;
//   // List<Map<String, dynamic>> get allReports => [..._allChatReports, ..._allAccountReports];


//    Future<void> initializeAdminData() async {
//     DebugHelper.logInfo('Initializing admin data...');
    
//     try {
//       _setError(null);
      
//       // Load all data in parallel for better performance
//       await Future.wait([
//            loadAllCategories(),
//         loadAllUsers(),
     
//         loadAllProducts(),
//         loadAllBanners(),
//         loadSupportRequests(),
//         loadAllReports(),
//       ]);
      
//       DebugHelper.logInfo('Admin data initialization completed');
//     } catch (e) {
//       DebugHelper.logError('Failed to initialize admin data: $e');
//       _setError('Failed to initialize admin data: $e');
//     }
//   }

//   Future<void> verifyUserEmail(String userId) async {
//   try {
//     await _firestore.collection('users').doc(userId).update({
//       'isEmailVerified': true,
//       'emailVerifiedAt': FieldValue.serverTimestamp(),
//       'emailVerifiedBy': 'admin', // Track who verified it
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
    
//     // Update local data
//     final userIndex = _allUsers.indexWhere((user) => user['id'] == userId);
//     if (userIndex != -1) {
//       _allUsers[userIndex]['isEmailVerified'] = true;
//       _allUsers[userIndex]['emailVerifiedAt'] = Timestamp.now();
//       _allUsers[userIndex]['emailVerifiedBy'] = 'admin';
//       _updateLastUpdated();
//       notifyListeners();
//     }
    
//     // Log admin action
//     await _logAdminAction('verify_email', userId, 'Email verified by admin');
    
//   } catch (e) {
//     DebugHelper.logError('Error verifying user email: $e');
//     _setError('Failed to verify email: $e');
//     rethrow;
//   }
// }

// // Verify user phone manually
// Future<void> verifyUserPhone(String userId) async {
//   try {
//     await _firestore.collection('users').doc(userId).update({
//       'isPhoneVerified': true,
//       'phoneVerifiedAt': FieldValue.serverTimestamp(),
//       'phoneVerifiedBy': 'admin', // Track who verified it
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
    
//     // Update local data
//     final userIndex = _allUsers.indexWhere((user) => user['id'] == userId);
//     if (userIndex != -1) {
//       _allUsers[userIndex]['isPhoneVerified'] = true;
//       _allUsers[userIndex]['phoneVerifiedAt'] = Timestamp.now();
//       _allUsers[userIndex]['phoneVerifiedBy'] = 'admin';
//       _updateLastUpdated();
//       notifyListeners();
//     }
    
//     // Log admin action
//     await _logAdminAction('verify_phone', userId, 'Phone verified by admin');
    
//   } catch (e) {
//     DebugHelper.logError('Error verifying user phone: $e');
//     _setError('Failed to verify phone: $e');
//     rethrow;
//   }
// }

// // Reset user password
// Future<void> resetUserPassword(String userId) async {
//   try {
//     // Get user email first
//     final userDoc = await _firestore.collection('users').doc(userId).get();
//     if (!userDoc.exists) {
//       throw Exception('User not found');
//     }
    
//     final userData = userDoc.data() as Map<String, dynamic>;
//     final userEmail = userData['email'] as String?;
    
//     if (userEmail == null || userEmail.isEmpty) {
//       throw Exception('User email not found');
//     }
    
//     // Send password reset email using Firebase Auth
//     await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail);
    
//     // Update user document to track password reset
//     await _firestore.collection('users').doc(userId).update({
//       'passwordResetSentAt': FieldValue.serverTimestamp(),
//       'passwordResetBy': 'admin',
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
    
//     // Update local data
//     final userIndex = _allUsers.indexWhere((user) => user['id'] == userId);
//     if (userIndex != -1) {
//       _allUsers[userIndex]['passwordResetSentAt'] = Timestamp.now();
//       _allUsers[userIndex]['passwordResetBy'] = 'admin';
//       _updateLastUpdated();
//       notifyListeners();
//     }
    
//     // Log admin action
//     await _logAdminAction('reset_password', userId, 'Password reset email sent by admin');
    
//   } catch (e) {
//     DebugHelper.logError('Error resetting user password: $e');
//     _setError('Failed to reset password: $e');
//     rethrow;
//   }
// }

// // Enhanced updateUserStatus method with better tracking

// Future<void> updateUserStatus(String userId, bool isActive) async {
//   try {
//     await _firestore.collection('users').doc(userId).update({
//       'isActive': isActive,
//       'statusUpdatedAt': FieldValue.serverTimestamp(),
//       'statusUpdatedBy': 'admin',
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
    
//     final userIndex = _allUsers.indexWhere((user) => user['id'] == userId);
//     if (userIndex != -1) {
//       _allUsers[userIndex]['isActive'] = isActive;
//       _allUsers[userIndex]['statusUpdatedAt'] = Timestamp.now();
//       _allUsers[userIndex]['statusUpdatedBy'] = 'admin';
//       _updateLastUpdated();
//       notifyListeners();
//     }
    
//     // Log admin action
//     await _logAdminAction(
//       isActive ? 'activate_user' : 'block_user', 
//       userId, 
//       isActive ? 'User activated by admin' : 'User blocked by admin'
//     );
    
//   } catch (e) {
//     DebugHelper.logError('Error updating user status: $e');
//     _setError('Failed to update user status: $e');
//     rethrow;
//   }
// }

// // Enhanced deleteUser method with better cleanup

// Future<void> deleteUser(String userId) async {
//   try {
//     // Get user data first for logging
//     final userDoc = await _firestore.collection('users').doc(userId).get();
//     final userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};
    
//     // Delete user's products first
//     final userProductsQuery = await _firestore
//         .collection('items')
//         .where('sellerId', isEqualTo: userId)
//         .get();
    
//     final batch = _firestore.batch();
    
//     // Delete all user's products
//     for (final doc in userProductsQuery.docs) {
//       batch.delete(doc.reference);
//     }
    
//     // Delete user's chats
//     final userChatsQuery = await _firestore
//         .collection('chats')
//         .where('participants', arrayContains: userId)
//         .get();
    
//     for (final doc in userChatsQuery.docs) {
//       batch.delete(doc.reference);
//     }
    
//     // Delete user's location data
//     final locationRef = _firestore
//         .collection('users')
//         .doc(userId)
//         .collection('location')
//         .doc('current');
    
//     batch.delete(locationRef);
    
//     // Delete user document
//     batch.delete(_firestore.collection('users').doc(userId));
    
//     // Commit all deletions
//     await batch.commit();
    
//     // Remove from local data
//     _allUsers.removeWhere((user) => user['id'] == userId);
//     _totalUsers = _allUsers.length;
//     _updateLastUpdated();
//     notifyListeners();
    
//     // Log admin action
//     await _logAdminAction('delete_user', userId, 'User and all associated data deleted by admin');
    
//   } catch (e) {
//     DebugHelper.logError('Error deleting user: $e');
//     _setError('Failed to delete user: $e');
//     rethrow;
//   }
// }

// // Send notification to user
// Future<void> sendNotificationToUser(String userId, String title, String message) async {
//   try {
//     await _firestore.collection('notifications').add({
//       'userId': userId,
//       'title': title,
//       'message': message,
//       'type': 'admin_message',
//       'isRead': false,
//       'createdAt': FieldValue.serverTimestamp(),
//       'sentBy': 'admin',
//     });
    
//     // Log admin action
//     await _logAdminAction('send_notification', userId, 'Notification sent: $title');
    
//   } catch (e) {
//     DebugHelper.logError('Error sending notification: $e');
//     _setError('Failed to send notification: $e');
//     rethrow;
//   }
// }

// // Get user's products count
// Future<int> getUserProductsCount(String userId) async {
//   try {
//     final snapshot = await _firestore
//         .collection('items')
//         .where('sellerId', isEqualTo: userId)
//         .get();
    
//     return snapshot.docs.length;
//   } catch (e) {
//     DebugHelper.logError('Error getting user products count: $e');
//     return 0;
//   }
// }

// // Get user's recent activity
// Future<List<Map<String, dynamic>>> getUserRecentActivity(String userId) async {
//   try {
//     final activities = <Map<String, dynamic>>[];
    
//     // Get recent products
//     final recentProducts = await _firestore
//         .collection('items')
//         .where('sellerId', isEqualTo: userId)
//         .orderBy('createdAt', descending: true)
//         .limit(5)
//         .get();
    
//     for (final doc in recentProducts.docs) {
//       final data = doc.data();
//       activities.add({
//         'type': 'product_created',
//         'title': 'Created product: ${data['itemTitle']}',
//         'timestamp': data['createdAt'],
//         'data': data,
//       });
//     }
    
//     // Get recent chats
//     final recentChats = await _firestore
//         .collection('chats')
//         .where('participants', arrayContains: userId)
//         .orderBy('lastMessageTime', descending: true)
//         .limit(5)
//         .get();
    
//     for (final doc in recentChats.docs) {
//       final data = doc.data();
//       activities.add({
//         'type': 'chat_activity',
//         'title': 'Chat activity',
//         'timestamp': data['lastMessageTime'],
//         'data': data,
//       });
//     }
    
//     // Sort by timestamp
//     activities.sort((a, b) {
//       final timestampA = a['timestamp'] as Timestamp?;
//       final timestampB = b['timestamp'] as Timestamp?;
      
//       if (timestampA == null) return 1;
//       if (timestampB == null) return -1;
      
//       return timestampB.compareTo(timestampA);
//     });
    
//     return activities.take(10).toList();
    
//   } catch (e) {
//     DebugHelper.logError('Error getting user recent activity: $e');
//     return [];
//   }
// }

// // Log admin actions for audit trail
// Future<void> _logAdminAction(String action, String targetId, String description) async {
//   try {
//     await _firestore.collection('admin_logs').add({
//       'action': action,
//       'targetId': targetId,
//       'targetType': 'user',
//       'description': description,
//       'adminId': 'current_admin', // Replace with actual admin ID
//       'timestamp': FieldValue.serverTimestamp(),
//       'ipAddress': '', // Add IP tracking if needed
//     });
//   } catch (e) {
//     DebugHelper.logError('Error logging admin action: $e');
//     // Don't throw error here as it's just logging
//   }
// }

// // Bulk operations for users
// Future<void> bulkUpdateUserStatus(List<String> userIds, bool isActive) async {
//   try {
//     final batch = _firestore.batch();
    
//     for (final userId in userIds) {
//       final userRef = _firestore.collection('users').doc(userId);
//       batch.update(userRef, {
//         'isActive': isActive,
//         'statusUpdatedAt': FieldValue.serverTimestamp(),
//         'statusUpdatedBy': 'admin',
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//     }
    
//     await batch.commit();
    
//     // Update local data
//     for (final userId in userIds) {
//       final userIndex = _allUsers.indexWhere((user) => user['id'] == userId);
//       if (userIndex != -1) {
//         _allUsers[userIndex]['isActive'] = isActive;
//         _allUsers[userIndex]['statusUpdatedAt'] = Timestamp.now();
//         _allUsers[userIndex]['statusUpdatedBy'] = 'admin';
//       }
//     }
    
//     _updateLastUpdated();
//     notifyListeners();
    
//     // Log bulk action
//     await _logAdminAction(
//       'bulk_update_status',
//       userIds.join(','),
//       'Bulk ${isActive ? 'activated' : 'blocked'} ${userIds.length} users'
//     );
    
//   } catch (e) {
//     DebugHelper.logError('Error bulk updating user status: $e');
//     _setError('Failed to bulk update user status: $e');
//     rethrow;
//   }
// }

// // Export users data
// Future<String> exportUsersData({
//   List<String>? userIds,
//   String format = 'csv',
// }) async {
//   try {
//     final usersToExport = userIds != null 
//         ? _allUsers.where((user) => userIds.contains(user['id'])).toList()
//         : _allUsers;
    
//     if (format == 'csv') {
//       final csv = StringBuffer();
      
//       // CSV Headers
//       csv.writeln('ID,Type,Name/Company,Email,Phone,Status,Email Verified,Phone Verified,Language,Created At');
      
//       // CSV Data
//       for (final user in usersToExport) {
//         final name = user['type'] == 'company' 
//             ? (user['companyName'] ?? '')
//             : (user['name'] ?? '');
        
//         csv.writeln([
//           user['id'],
//           user['type'],
//           name,
//           user['email'] ?? '',
//           user['phone'] ?? '',
//           user['isActive'] == true ? 'Active' : 'Blocked',
//           user['isEmailVerified'] == true ? 'Yes' : 'No',
//           user['isPhoneVerified'] == true ? 'Yes' : 'No',
//           user['language'] ?? 'English',
//           _formatDate(user['createdAt']),
//         ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
//       }
      
//       return csv.toString();
//     }
    
//     // Add other formats (JSON, Excel) as needed
//     return '';
    
//   } catch (e) {
//     DebugHelper.logError('Error exporting users data: $e');
//     rethrow;
//   }
// }

// // Helper method to format date for export
// String _formatDate(dynamic date) {
//   if (date == null) return '';
//   try {
//     if (date is Timestamp) {
//       return date.toDate().toIso8601String();
//     } else if (date is DateTime) {
//       return date.toIso8601String();
//     } else if (date is String) {
//       return DateTime.parse(date).toIso8601String();
//     }
//     return '';
//   } catch (_) {
//     return '';
//   }
// }

//   // Enhanced state management
//   void setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }

//   void _setDashboardLoading(bool loading) {
//     _isDashboardLoading = loading;
//     notifyListeners();
//   }

//   void _setAnalyticsLoading(bool loading) {
//     _isAnalyticsLoading = loading;
//     notifyListeners();
//   }

//   void _setError(String? error) {
//     _error = error;
//     notifyListeners();
//   }

//   void _updateLastUpdated() {
//     _lastUpdated = DateTime.now();
//   }

//   // ENHANCED DASHBOARD LOADING WITH ANALYTICS
//   Future<void> loadDashboardData() async {
//     if (_isDashboardLoading) return; // Prevent multiple simultaneous loads
    
//     _setDashboardLoading(true);
//     _setError(null);

//     try {
//       // Load basic stats in parallel
//       await Future.wait([
//         _loadUserStats(),
//         _loadProductStats(),
//         _loadChatStats(),
//         _loadSupportStats(),
//         _loadRecentData(),
//       ]);

//       _updateLastUpdated();
//     } catch (e) {
//       DebugHelper.logError('Failed to load dashboard data: $e');
//       _setError('Failed to load dashboard data: $e');
//     }

//     _setDashboardLoading(false);
//   }

//   // NEW: Enhanced analytics loading
//   Future<void> loadAnalyticsData() async {
//     if (_isAnalyticsLoading) return;
    
//     _setAnalyticsLoading(true);

//     try {
//       // Check cache first
//       if (_shouldUseCache()) {
//         _loadFromCache();
//         _setAnalyticsLoading(false);
//         return;
//       }

//       // Load analytics in parallel
//       await Future.wait([
//         _loadGrowthMetrics(),
//         _loadTopSearches(),
//         _loadCategoryTrends(),
//         _loadLocationAnalytics(),
//         _loadTopUsers(),
//         _loadRecentActivity(),
//       ]);

//       _updateAnalyticsCache();
//       _updateLastUpdated();
//     } catch (e) {
//       DebugHelper.logError('Failed to load analytics data: $e');
//       _setError('Failed to load analytics data: $e');
//     }

//     _setAnalyticsLoading(false);
//   }

//   // NEW: Refresh all data
//   Future<void> refreshDashboardData() async {
//     _clearCache();
//     await Future.wait([
//       loadDashboardData(),
//       loadAnalyticsData(),
//     ]);
//   }

//   // ENHANCED USER STATS WITH ANALYTICS
//   Future<void> _loadUserStats() async {
//     try {
//       final now = DateTime.now();
//       final todayStart = DateTime(now.year, now.month, now.day);
//       final weekStart = now.subtract(const Duration(days: 7));
//       final monthStart = DateTime(now.year, now.month - 1, now.day);

//       // Get all users
//       final usersSnapshot = await _firestore.collection('users').get();
//       _totalUsers = usersSnapshot.docs.length;

//       // Calculate today's new users
//       final todayUsersQuery = await _firestore
//           .collection('users')
//           .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
//           .get();
//       _todayNewUsers = todayUsersQuery.docs.length;

//       // Calculate weekly new users
//       final weeklyUsersQuery = await _firestore
//           .collection('users')
//           .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
//           .get();
//       _newUsersThisWeek = weeklyUsersQuery.docs.length;

//       // Calculate monthly growth
//       final monthlyUsersQuery = await _firestore
//           .collection('users')
//           .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
//           .get();
//       final monthlyNewUsers = monthlyUsersQuery.docs.length;

//       // Calculate growth percentage
//       final previousMonthUsers = _totalUsers - monthlyNewUsers;
//       if (previousMonthUsers > 0) {
//         _userGrowthPercentage = (monthlyNewUsers / previousMonthUsers) * 100;
//         _userTrend = _userGrowthPercentage > 0 ? 'up' : 'down';
//       }

//       // Get recent users
//       final recentUsersSnapshot = await _firestore
//           .collection('users')
//           .orderBy('createdAt', descending: true)
//           .limit(10)
//           .get();

//       _recentUsers = recentUsersSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();

//     } catch (e) {
//       DebugHelper.logError('Error loading user stats: $e');
//     }
//   }

//   // ENHANCED PRODUCT STATS WITH ANALYTICS
//   Future<void> _loadProductStats() async {
//     try {
//       final now = DateTime.now();
//       final todayStart = DateTime(now.year, now.month, now.day);
//       final weekStart = now.subtract(const Duration(days: 7));
//       final monthStart = DateTime(now.year, now.month - 1, now.day);

//       // Get all products
//       final productsSnapshot = await _firestore
//           .collection('items')
//           .where('status', isEqualTo: 'active')
//           .get();
//       _totalProducts = productsSnapshot.docs.length;

//       // Calculate today's new products
//       final todayProductsQuery = await _firestore
//           .collection('items')
//           .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
//           .where('status', isEqualTo: 'active')
//           .get();
//       _todayNewProducts = todayProductsQuery.docs.length;

//       // Calculate weekly new products
//       final weeklyProductsQuery = await _firestore
//           .collection('items')
//           .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
//           .where('status', isEqualTo: 'active')
//           .get();
//       _newListingsThisWeek = weeklyProductsQuery.docs.length;

//       // Calculate monthly growth
//       final monthlyProductsQuery = await _firestore
//           .collection('items')
//           .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
//           .where('status', isEqualTo: 'active')
//           .get();
//       final monthlyNewProducts = monthlyProductsQuery.docs.length;

//       // Calculate growth percentage
//       final previousMonthProducts = _totalProducts - monthlyNewProducts;
//       if (previousMonthProducts > 0) {
//         _listingGrowthPercentage = (monthlyNewProducts / previousMonthProducts) * 100;
//         _listingTrend = _listingGrowthPercentage > 0 ? 'up' : 'down';
//       }

//       // Get recent products
//       final recentProductsSnapshot = await _firestore
//           .collection('items')
//           .orderBy('createdAt', descending: true)
//           .limit(10)
//           .get();

//       _recentProducts = recentProductsSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();

//     } catch (e) {
//       DebugHelper.logError('Error loading product stats: $e');
//     }
//   }

//   // ENHANCED CHAT STATS
//   Future<void> _loadChatStats() async {
//     try {
//       final chatsSnapshot = await _firestore
//           .collection('chats')
//           .where('isActive', isEqualTo: true)
//           .get();
//       _activeChats = chatsSnapshot.docs.length;

//       // Calculate average response time (mock calculation)
//       // In real implementation, you'd analyze actual message timestamps
//       _averageResponseTime = 5 + Random().nextInt(10);

//       // Calculate chat growth (simplified)
//       final weekAgo = DateTime.now().subtract(const Duration(days: 7));
//       final recentChatsSnapshot = await _firestore
//           .collection('chats')
//           .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
//           .get();
      
//       final weeklyChats = recentChatsSnapshot.docs.length;
//       if (_activeChats > weeklyChats) {
//         _chatGrowthPercentage = (weeklyChats / (_activeChats - weeklyChats)) * 100;
//         _chatTrend = _chatGrowthPercentage > 0 ? 'up' : 'down';
//       }
//     } catch (e) {
//       DebugHelper.logError('Error loading chat stats: $e');
//     }
//   }

//   Future<void> _loadSupportStats() async {
//     try {
//       final supportSnapshot = await _firestore
//           .collection('contact_submissions')
//           .where('status', isEqualTo: 'pending')
//           .get();
//       _pendingSupportRequests = supportSnapshot.docs.length;
//     } catch (e) {
//       DebugHelper.logError('Error loading support stats: $e');
//     }
//   }

//   Future<void> _loadRecentData() async {
//     // Enhanced with actual revenue calculation
//     try {
//       // Calculate revenue from premium features, featured listings, etc.
//       // This is a simplified calculation - adjust based on your business model
//       final now = DateTime.now();
//       final monthStart = DateTime(now.year, now.month, 1);
      
//       // Example: Featured listings revenue
//       final featuredListingsSnapshot = await _firestore
//           .collection('payments')
//           .where('type', isEqualTo: 'featured_listing')
//           .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
//           .get();
      
//       _monthlyRevenue = featuredListingsSnapshot.docs.fold<int>(0, (sum, doc) {
//         final amount = doc.data()['amount'] as int? ?? 0;
//         return sum + amount;
//       });

//       // Mock total revenue calculation
//       _totalRevenue = _monthlyRevenue * 12; // Simplified

//       // Mock orders for now
//       _totalOrders = 156 + Random().nextInt(50);

//       // Calculate revenue growth
//       final previousMonth = DateTime(now.year, now.month - 1, 1);
//       final previousMonthEnd = DateTime(now.year, now.month, 0);
      
//       final previousMonthSnapshot = await _firestore
//           .collection('payments')
//           .where('type', isEqualTo: 'featured_listing')
//           .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(previousMonth))
//           .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(previousMonthEnd))
//           .get();
      
//       final previousMonthRevenue = previousMonthSnapshot.docs.fold<int>(0, (sum, doc) {
//         final amount = doc.data()['amount'] as int? ?? 0;
//         return sum + amount;
//       });

//       if (previousMonthRevenue > 0) {
//         _revenueGrowthPercentage = ((_monthlyRevenue - previousMonthRevenue) / previousMonthRevenue) * 100;
//         _revenueTrend = _revenueGrowthPercentage > 0 ? 'up' : 'down';
//       }

//     } catch (e) {
//       DebugHelper.logError('Error loading revenue data: $e');
//       // Fallback to mock data
//       _totalOrders = 156;
//       _totalRevenue = 45600;
//       _monthlyRevenue = 8500;
//     }
//   }

//   // NEW ANALYTICS METHODS

//   Future<void> _loadGrowthMetrics() async {
//     // Growth metrics are calculated in individual stat methods
//     // This method can be used for additional complex calculations
//   }

//   Future<void> _loadTopSearches() async {
//     try {
//       // In a real app, you'd have a searches collection
//       // For now, creating realistic mock data
//       _topSearches = [
//         {'term': 'iPhone 14 Pro', 'count': 1250},
//         {'term': 'Samsung Galaxy', 'count': 980},
//         {'term': 'MacBook Pro', 'count': 765},
//         {'term': 'Car Toyota', 'count': 654},
//         {'term': 'House for sale', 'count': 543},
//         {'term': 'Laptop Dell', 'count': 432},
//         {'term': 'Mobile Huawei', 'count': 321},
//         {'term': 'Bike Honda', 'count': 298},
//       ];
//     } catch (e) {
//       DebugHelper.logError('Error loading top searches: $e');
//     }
//   }

//   Future<void> _loadCategoryTrends() async {
//     try {
//       // Get products grouped by category
//       final productsSnapshot = await _firestore
//           .collection('items')
//           .where('status', isEqualTo: 'active')
//           .get();

//       final categoryCount = <String, int>{};
//       final total = productsSnapshot.docs.length;

//       for (final doc in productsSnapshot.docs) {
//         final categoryName = doc.data()['categoryName'] as String? ?? 'Unknown';
//         categoryCount[categoryName] = (categoryCount[categoryName] ?? 0) + 1;
//       }

//       _categoryTrends = categoryCount.entries
//           .map((entry) => {
//                 'name': entry.key,
//                 'count': entry.value,
//                 'percentage': total > 0 ? (entry.value / total) * 100 : 0.0,
//               })
//           .toList()
//         ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

//     } catch (e) {
//       DebugHelper.logError('Error loading category trends: $e');
//     }
//   }

//   Future<void> _loadLocationAnalytics() async {
//     try {
//       // Get products with location data
//       final productsSnapshot = await _firestore
//           .collection('items')
//           .where('status', isEqualTo: 'active')
//           .get();

//       final cityCount = <String, Map<String, dynamic>>{};

//       for (final doc in productsSnapshot.docs) {
//         final data = doc.data();
//         final cityName = data['cityName'] as String? ?? 'Unknown';
        
//         if (!cityCount.containsKey(cityName)) {
//           cityCount[cityName] = {
//             'name': cityName,
//             'userCount': 0,
//             'listingCount': 0,
//             'isGrowing': Random().nextBool(),
//           };
//         }
        
//         cityCount[cityName]!['listingCount'] = 
//             (cityCount[cityName]!['listingCount'] as int) + 1;
//       }

//       // Get user counts by city
//       final usersSnapshot = await _firestore.collection('users').get();
//       for (final doc in usersSnapshot.docs) {
//         final cityName = doc.data()['cityName'] as String? ?? 'Unknown';
//         if (cityCount.containsKey(cityName)) {
//           cityCount[cityName]!['userCount'] = 
//               (cityCount[cityName]!['userCount'] as int) + 1;
//         }
//       }

//       _topCities = cityCount.values.toList()
//         ..sort((a, b) => 
//             (b['listingCount'] as int).compareTo(a['listingCount'] as int))
//         ..take(10).toList();

//       // Generate heatmap data (simplified)
//       _locationData = List.generate(25, (index) => {
//         'intensity': Random().nextDouble(),
//         'region': 'Region ${index + 1}',
//       });

//     } catch (e) {
//       DebugHelper.logError('Error loading location analytics: $e');
//     }
//   }

//   Future<void> _loadTopUsers() async {
//     try {
//       // Get users with their listing counts
//       final usersSnapshot = await _firestore.collection('users').get();
//       final userListingCounts = <String, Map<String, dynamic>>{};

//       // Initialize user data
//       for (final doc in usersSnapshot.docs) {
//         final data = doc.data();
//         userListingCounts[doc.id] = {
//           'id': doc.id,
//           'companyName': data['companyName'],
//           'email': data['email'],
//           'type': data['type'],
//           'listingCount': 0,
//         };
//       }

//       // Count listings per user
//       final productsSnapshot = await _firestore
//           .collection('items')
//           .where('status', isEqualTo: 'active')
//           .get();

//       for (final doc in productsSnapshot.docs) {
//         final sellerId = doc.data()['sellerId'] as String?;
//         if (sellerId != null && userListingCounts.containsKey(sellerId)) {
//           userListingCounts[sellerId]!['listingCount'] = 
//               (userListingCounts[sellerId]!['listingCount'] as int) + 1;
//         }
//       }

//       _topUsers = userListingCounts.values
//           .where((user) => (user['listingCount'] as int) > 0)
//           .toList()
//         ..sort((a, b) => 
//             (b['listingCount'] as int).compareTo(a['listingCount'] as int))
//         ..take(10).toList();

//     } catch (e) {
//       DebugHelper.logError('Error loading top users: $e');
//     }
//   }

//   Future<void> _loadRecentActivity() async {
//     try {
//       final activities = <Map<String, dynamic>>[];

//       // Get recent user registrations
//       final recentUsersSnapshot = await _firestore
//           .collection('users')
//           .orderBy('createdAt', descending: true)
//           .limit(5)
//           .get();

//       for (final doc in recentUsersSnapshot.docs) {
//         final data = doc.data();
//         activities.add({
//           'type': 'user_registered',
//           'message': '${data['companyName'] ?? data['email'] ?? 'New user'} registered',
//           'timestamp': data['createdAt'],
//         });
//       }

//       // Get recent product additions
//       final recentProductsSnapshot = await _firestore
//           .collection('items')
//           .orderBy('createdAt', descending: true)
//           .limit(5)
//           .get();

//       for (final doc in recentProductsSnapshot.docs) {
//         final data = doc.data();
//         activities.add({
//           'type': 'product_added',
//           'message': 'New product "${data['itemTitle'] ?? 'Unknown'}" added',
//           'timestamp': data['createdAt'],
//         });
//       }

//       // Get recent support requests
//       final recentSupportSnapshot = await _firestore
//           .collection('contact_submissions')
//           .orderBy('createdAt', descending: true)
//           .limit(3)
//           .get();

//       for (final doc in recentSupportSnapshot.docs) {
//         final data = doc.data();
//         activities.add({
//           'type': 'support_request',
//           'message': 'New support request: ${data['subject'] ?? 'General inquiry'}',
//           'timestamp': data['createdAt'],
//         });
//       }

//       // Sort all activities by timestamp
//       activities.sort((a, b) {
//         final timestampA = a['timestamp'] as Timestamp?;
//         final timestampB = b['timestamp'] as Timestamp?;
        
//         if (timestampA == null) return 1;
//         if (timestampB == null) return -1;
        
//         return timestampB.compareTo(timestampA);
//       });

//       _recentActivity = activities.take(10).toList();

//     } catch (e) {
//       DebugHelper.logError('Error loading recent activity: $e');
//     }
//   }

//   // CACHING SYSTEM

//   bool _shouldUseCache() {
//     if (_lastCacheUpdate == null) return false;
//     return DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
//   }

//   void _updateAnalyticsCache() {
//     _analyticsCache.clear();
//     _analyticsCache.addAll({
//       'topSearches': _topSearches,
//       'categoryTrends': _categoryTrends,
//       'locationData': _locationData,
//       'topCities': _topCities,
//       'topUsers': _topUsers,
//       'recentActivity': _recentActivity,
//     });
//     _lastCacheUpdate = DateTime.now();
//   }

//   void _loadFromCache() {
//     _topSearches = List<Map<String, dynamic>>.from(
//         _analyticsCache['topSearches'] ?? []);
//     _categoryTrends = List<Map<String, dynamic>>.from(
//         _analyticsCache['categoryTrends'] ?? []);
//     _locationData = List<Map<String, dynamic>>.from(
//         _analyticsCache['locationData'] ?? []);
//     _topCities = List<Map<String, dynamic>>.from(
//         _analyticsCache['topCities'] ?? []);
//     _topUsers = List<Map<String, dynamic>>.from(
//         _analyticsCache['topUsers'] ?? []);
//     _recentActivity = List<Map<String, dynamic>>.from(
//         _analyticsCache['recentActivity'] ?? []);
//   }

//   void _clearCache() {
//     _analyticsCache.clear();
//     _categoryCache.clear();
//     _lastCacheUpdate = null;
//   }

//   // EXISTING CATEGORY METHODS (OPTIMIZED)

//   List<Map<String, dynamic>> getSubCategories(String parentId) {
//     if (parentId.isEmpty || _allCategories.isEmpty) {
//       return [];
//     }

//     // Check cache first
//     if (_categoryCache.containsKey(parentId)) {
//       return _categoryCache[parentId]!;
//     }

//     try {
//       final subCategories = _allCategories.where((category) {
//         final categoryParentId = category['parentId']?.toString();
//         final categoryIsActive = category['isActive'];
        
//         return categoryParentId == parentId && categoryIsActive == true;
//       }).toList();
      
//       subCategories.sort((a, b) {
//         final orderA = (a['order'] as num?)?.toInt() ?? 0;
//         final orderB = (b['order'] as num?)?.toInt() ?? 0;
        
//         if (orderA != orderB) {
//           return orderA.compareTo(orderB);
//         }
        
//         final nameA = a['name']?.toString() ?? '';
//         final nameB = b['name']?.toString() ?? '';
//         return nameA.compareTo(nameB);
//       });
      
//       // Cache the result
//       _categoryCache[parentId] = subCategories;
      
//       return subCategories;
//     } catch (e) {
//       DebugHelper.logError('Error in getSubCategories: $e');
//       return [];
//     }
//   }

//   List<Map<String, dynamic>> getMainCategories() {
//     DebugHelper.logInfo('getMainCategories called. Total categories: ${_allCategories.length}');
//     if (_allCategories.isEmpty) {
//       DebugHelper.logInfo('No categories available');
//       return [];
//     }

//     // Check cache first
//     const cacheKey = 'main_categories';
//     if (_categoryCache.containsKey(cacheKey)) {
//       return _categoryCache[cacheKey]!;
//     }
    
//     try {
//       final mainCategories = _allCategories.where((category) {
//         final parentId = category['parentId'];
//         final level = category['level'];
//         final isActive = category['isActive'];
        
//         final isMainCategory = (level != null && level == 0) || 
//                               (parentId == null || parentId.toString().isEmpty);
        
//         return isMainCategory && isActive == true;
//       }).toList();
      
//       DebugHelper.logInfo('Found ${mainCategories.length} main categories');

//       mainCategories.sort((a, b) {
//         final orderA = (a['order'] as num?)?.toInt() ?? 0;
//         final orderB = (b['order'] as num?)?.toInt() ?? 0;
        
//         if (orderA != orderB) {
//           return orderA.compareTo(orderB);
//         }
        
//         final dateA = a['createdAt'] as Timestamp?;
//         final dateB = b['createdAt'] as Timestamp?;
        
//         if (dateA != null && dateB != null) {
//           return dateA.compareTo(dateB);
//         }
        
//         return 0;
//       });
      
//       // Cache the result
//       _categoryCache[cacheKey] = mainCategories;
      
//       return mainCategories;
//     } catch (e) {
//       DebugHelper.logError('Error in getMainCategories: $e');
//       return [];
//     }
//   }

//   Future<void> loadAllCategories() async {
//     if (_isLoading) return;
    
//     setLoading(true);
//     try {
//       final categoriesSnapshot = await _firestore
//           .collection('categories')
//           .orderBy('createdAt', descending: true) // Sort by creation date, newest first
//           .get(); // Remove limit to get all categories initially

//       _allCategories = categoriesSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
      
//       // Sort categories by order and creation date
//       _allCategories.sort((a, b) {
//         final orderA = a['order'] ?? 0;
//         final orderB = b['order'] ?? 0;
//         if (orderA != orderB) {
//           return orderA.compareTo(orderB);
//         }
        
//         final dateA = a['createdAt'] as Timestamp?;
//         final dateB = b['createdAt'] as Timestamp?;
//         if (dateA != null && dateB != null) {
//           return dateB.compareTo(dateA); // Newest first
//         }
//         return 0;
//       });
      
//       // Debug logging
//       DebugHelper.logInfo('Loaded ${_allCategories.length} categories from Firestore');
//       if (_allCategories.isNotEmpty) {
//         DebugHelper.logInfo('First category: ${_allCategories.first}');
//       }
      
//       // Clear cache when categories are reloaded
//       _categoryCache.clear();
//       _updateLastUpdated();
//       notifyListeners();
//     } catch (e) {
//       DebugHelper.logError('Error loading categories: $e');
//       _setError('Failed to load categories: $e');
//     }
//     setLoading(false);
//   }

//   // Add method to load more categories
//   Future<void> loadMoreCategories() async {
//     if (_isLoading || _allCategories.isEmpty) return;
    
//     try {
//       // Get the last document from current list
//       final lastDoc = await _firestore
//           .collection('categories')
//           .doc(_allCategories.last['id'])
//           .get();

//       final nextCategoriesSnapshot = await _firestore
//           .collection('categories')
//           .orderBy('createdAt', descending: true)
//           .startAfterDocument(lastDoc)
//           .limit(20)
//           .get();

//       if (nextCategoriesSnapshot.docs.isNotEmpty) {
//         final newCategories = nextCategoriesSnapshot.docs.map((doc) {
//           Map<String, dynamic> data = doc.data();
//           data['id'] = doc.id;
//           return data;
//         }).toList();

//         _allCategories.addAll(newCategories);
        
//         // Clear cache when categories are updated
//         _categoryCache.clear();
//         _updateLastUpdated();
//         notifyListeners();
//       }
//     } catch (e) {
//       DebugHelper.logError('Error loading more categories: $e');
//       _setError('Failed to load more categories: $e');
//     }
//   }

//   // EXISTING METHODS (OPTIMIZED WITH ERROR HANDLING)

//   // User Management
//   Future<void> loadAllUsers() async {

    
//     setLoading(true);
//     try {
//       final usersSnapshot = await _firestore
//           .collection('users')
//           .orderBy('createdAt', descending: true)
//           .get();

//       _allUsers = usersSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
      
//       _updateLastUpdated();
//     } catch (e) {
//       DebugHelper.logError('Error loading users: $e');
//       _setError('Failed to load users: $e');
//     }
//     setLoading(false);
//   }

  

//   // Product Management
//   Future<void> loadAllProducts() async {
//     if (_isLoading) return;
    
//     setLoading(true);
//     try {
//       DebugHelper.logInfo('Loading products from Firestore...');
//       final productsSnapshot = await _firestore
//           .collection('items')
//           .get();

//       _allProducts = productsSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
      
//       DebugHelper.logInfo('Loaded ${_allProducts.length} products from Firestore');
//       if (_allProducts.isNotEmpty) {
//         DebugHelper.logInfo('First product: ${_allProducts.first['itemTitle'] ?? 'No title'}');
//       }
      
//       _updateLastUpdated();
//       notifyListeners(); // Add this to notify listeners that data has been updated
//     } catch (e) {
//       DebugHelper.logError('Error loading products: $e');
//       _setError('Failed to load products: $e');
//     }
//     setLoading(false);
//   }

//   Future<void> createProduct(Map<String, dynamic> productData) async {
//     setLoading(true);
//     try {
//       final docRef = await _firestore.collection('items').add({
//         ...productData,
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       productData['id'] = docRef.id;
//       productData['createdAt'] = Timestamp.now();
//       _allProducts.insert(0, productData);
//       _totalProducts = _allProducts.length;
//       _updateLastUpdated();
//       notifyListeners();
//     } catch (e) {
//       DebugHelper.logError('Error creating product: $e');
//       _setError('Failed to create product: $e');
//       rethrow;
//     }
//     setLoading(false);
//   }

//   Future<void> updateProductStatus(String productId, String status) async {
//     try {
//       await _firestore.collection('items').doc(productId).update({
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
      
//       final productIndex = _allProducts.indexWhere((product) => product['id'] == productId);
//       if (productIndex != -1) {
//         _allProducts[productIndex]['status'] = status;
//         _updateLastUpdated();
//         notifyListeners();
//       }
//     } catch (e) {
//       DebugHelper.logError('Error updating product status: $e');
//       _setError('Failed to update product status: $e');
//     }
//   }

//   Future<void> deleteProduct(String productId) async {
//     try {
//       await _firestore.collection('items').doc(productId).delete();
      
//       _allProducts.removeWhere((product) => product['id'] == productId);
//       _totalProducts = _allProducts.length;
//       _updateLastUpdated();
//       notifyListeners();
//     } catch (e) {
//       DebugHelper.logError('Error deleting product: $e');
//       _setError('Failed to delete product: $e');
//     }
//   }

//   // ENHANCED CATEGORY MANAGEMENT

//   bool categoryExists(String categoryId) {
//     if (categoryId.isEmpty || _allCategories.isEmpty) {
//       return false;
//     }
//     return _allCategories.any((cat) => cat['id'] == categoryId);
//   }

//   Map<String, dynamic>? getCategoryDetails(String categoryId) {
//     if (categoryId.isEmpty || _allCategories.isEmpty) {
//       return null;
//     }
    
//     try {
//       return _allCategories.firstWhere(
//         (cat) => cat['id'] == categoryId,
//         orElse: () => <String, dynamic>{},
//       );
//     } catch (e) {
//       DebugHelper.logError('Error getting category details for $categoryId: $e');
//       return null;
//     }
//   }

//   bool hasSubCategories(String parentId) {
//     return getSubCategories(parentId).isNotEmpty;
//   }

//   int getCategoryLevel(String categoryId) {
//     final category = getCategoryDetails(categoryId);
//     if (category == null) return -1;
    
//     if (category['level'] != null) {
//       return (category['level'] as num).toInt();
//     }
    
//     int level = 0;
//     String? currentParentId = category['parentId']?.toString();
    
//     while (currentParentId != null && currentParentId.isNotEmpty && level < 5) {
//       level++;
//       final parent = getCategoryDetails(currentParentId);
//       if (parent == null) break;
//       currentParentId = parent['parentId']?.toString();
//     }
    
//     return level;
//   }

//   Map<String, dynamic> getCategoryHierarchy(String categoryId) {
//     final category = _allCategories.firstWhere(
//       (cat) => cat['id'] == categoryId,
//       orElse: () => <String, dynamic>{},
//     );
    
//     if (category.isEmpty) return {};
    
//     return {
//       'category': category,
//       'parent': category['parentId'] != null 
//           ? _allCategories.firstWhere(
//               (cat) => cat['id'] == category['parentId'],
//               orElse: () => <String, dynamic>{},
//             )
//           : null,
//       'children': getSubCategories(categoryId),
//     };
//   }

//  Future<void> createCategory(Map<String, dynamic> categoryData) async {
//   setLoading(true);
//   try {
//     final docRef = await _firestore.collection('categories').add({
//       ...categoryData,
//       'createdAt': FieldValue.serverTimestamp(),
//       'updatedAt': FieldValue.serverTimestamp(),
//     });

//     // Fetch the document to get the real timestamps
//     final doc = await docRef.get();
//     final data = doc.data();
//     data?['id'] = doc.id;

//     _allCategories.insert(0, data??{});

//     _categoryCache.clear();
//     _updateLastUpdated();
//     notifyListeners();
//   } catch (e) {
//     DebugHelper.logError('Error creating category: $e');
//     _setError('Failed to create category: $e');
//     rethrow;
//   }
//   setLoading(false);
// }

//  Future<void> updateCategory(String categoryId, Map<String, dynamic> categoryData) async {
//   setLoading(true);
//   try {
//     await _firestore.collection('categories').doc(categoryId).update({
//       ...categoryData,
//       'updatedAt': FieldValue.serverTimestamp(),
//     });

//     // Fetch the updated document to get the real timestamp
//     final doc = await _firestore.collection('categories').doc(categoryId).get();
//     final data = doc.data();
//     data?['id'] = categoryId;

//     final categoryIndex = _allCategories.indexWhere((category) => category['id'] == categoryId);
//     if (categoryIndex != -1) {
//       _allCategories[categoryIndex] = data??{};
//       _categoryCache.clear();
//       _updateLastUpdated();
//       notifyListeners();
//     }
//   } catch (e) {
//     DebugHelper.logError('Error updating category: $e');
//     _setError('Failed to update category: $e');
//     rethrow;
//   }
//   setLoading(false);
// }

//   Future<void> updateCategoryStatus(String categoryId, bool isActive) async {
//     try {
//       await _firestore.collection('categories').doc(categoryId).update({
//         'isActive': isActive,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
      
//       final categoryIndex = _allCategories.indexWhere((category) => category['id'] == categoryId);
//       if (categoryIndex != -1) {
//         _allCategories[categoryIndex]['isActive'] = isActive;
//         _categoryCache.clear();
//         _updateLastUpdated();
//         notifyListeners();
//       }
//     } catch (e) {
//       DebugHelper.logError('Error updating category status: $e');
//       _setError('Failed to update category status: $e');
//     }
//   }

//   Future<void> deleteCategory(String categoryId) async {
//     try {
//       final hasChildren = _allCategories.any((cat) => cat['parentId'] == categoryId);
//       if (hasChildren) {
//         throw Exception('Cannot delete category that has subcategories. Please delete subcategories first.');
//       }

//       final productsSnapshot = await _firestore
//           .collection('items')
//           .where('category', isEqualTo: categoryId)
//           .limit(1)
//           .get();
      
//       if (productsSnapshot.docs.isNotEmpty) {
//         throw Exception('Cannot delete category that has products. Please move or delete products first.');
//       }

//       await _firestore.collection('categories').doc(categoryId).delete();
      
//       _allCategories.removeWhere((category) => category['id'] == categoryId);
//       _categoryCache.clear();
//       _updateLastUpdated();
//       notifyListeners();
//     } catch (e) {
//       DebugHelper.logError('Error deleting category: $e');
//       _setError('Failed to delete category: $e');
//       rethrow;
//     }
//   }

//   // Support Management
//   Future<void> loadSupportRequests() async {
//     if (_isLoading) return;
    
//     setLoading(true);
//     try {
//       final supportSnapshot = await _firestore
//           .collection('contact_submissions')
//           .orderBy('createdAt', descending: true)
//           .get();

//       _supportRequests = supportSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
      
//       _updateLastUpdated();
//     } catch (e) {
//       DebugHelper.logError('Error loading support requests: $e');
//       _setError('Failed to load support requests: $e');
//     }
//     setLoading(false);
//   }

//   Future<void> updateSupportRequestStatus(String requestId, String status, {String? response}) async {
//     try {
//       Map<String, dynamic> updateData = {
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       };

//       if (response != null) {
//         updateData['adminResponse'] = response;
//         updateData['responseDate'] = FieldValue.serverTimestamp();
//       }

//       await _firestore.collection('contact_submissions').doc(requestId).update(updateData);
      
//       final requestIndex = _supportRequests.indexWhere((request) => request['id'] == requestId);
//       if (requestIndex != -1) {
//         _supportRequests[requestIndex]['status'] = status;
//         if (response != null) {
//           _supportRequests[requestIndex]['adminResponse'] = response;
//         }
//         _updateLastUpdated();
//         notifyListeners();
//       }
//     } catch (e) {
//       DebugHelper.logError('Error updating support request: $e');
//       _setError('Failed to update support request: $e');
//     }
//   }

//   // Banner Management
//   Future<void> loadAllBanners() async {
//     if (_isLoading) return;
    
//     setLoading(true);
//     try {
//       final bannersSnapshot = await _firestore
//           .collection('adBanners')
//           .orderBy('createdAt', descending: true)
//           .get();

//       _allBanners = bannersSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
      
//       _updateLastUpdated();
//     } catch (e) {
//       DebugHelper.logError('Error loading banners: $e');
//       _setError('Failed to load banners: $e');
//     }
//     setLoading(false);
//   }

//   Future<void> createBanner(Map<String, dynamic> bannerData) async {
//     setLoading(true);
//     try {
//       final docRef = await _firestore.collection('adBanners').add({
//         ...bannerData,
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       bannerData['id'] = docRef.id;
//       bannerData['createdAt'] = Timestamp.now();
//       _allBanners.insert(0, bannerData);
//       _updateLastUpdated();
//       notifyListeners();
//     } catch (e) {
//       DebugHelper.logError('Error creating banner: $e');
//       _setError('Failed to create banner: $e');
//       rethrow;
//     }
//     setLoading(false);
//   }

//   Future<void> updateBannerStatus(String bannerId, bool isActive) async {
//     try {
//       await _firestore.collection('adBanners').doc(bannerId).update({
//         'isActive': isActive,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
      
//       final bannerIndex = _allBanners.indexWhere((banner) => banner['id'] == bannerId);
//       if (bannerIndex != -1) {
//         _allBanners[bannerIndex]['isActive'] = isActive;
//         _updateLastUpdated();
//         notifyListeners();
//       }
//     } catch (e) {
//       DebugHelper.logError('Error updating banner status: $e');
//       _setError('Failed to update banner status: $e');
//     }
//   }

//   Future<void> deleteBanner(String bannerId) async {
//     try {
//       await _firestore.collection('adBanners').doc(bannerId).delete();
      
//       _allBanners.removeWhere((banner) => banner['id'] == bannerId);
//       _updateLastUpdated();
//       notifyListeners();
//     } catch (e) {
//       DebugHelper.logError('Error deleting banner: $e');
//       _setError('Failed to delete banner: $e');
//     }
//   }

//   // Chat Management
//   Future<void> loadChatConversations() async {
//     if (_isLoading) return;
    
//     setLoading(true);
//     try {
//       final chatsSnapshot = await _firestore
//           .collection('chats')
//           .orderBy('lastMessageTime', descending: true)
//           .limit(50)
//           .get();

//       _chatConversations = chatsSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
      
//       _updateLastUpdated();
//     } catch (e) {
//       DebugHelper.logError('Error loading chat conversations: $e');
//       _setError('Failed to load chat conversations: $e');
//     }
//     setLoading(false);
//   }

//   // Image Upload
//   Future<String> uploadImage(Uint8List imageData, String fileName) async {
//     try {
//       final ref = _storage.ref().child('admin_uploads/$fileName');
//       final uploadTask = ref.putData(imageData);
//       final snapshot = await uploadTask;
//       return await snapshot.ref.getDownloadURL();
//     } catch (e) {
//       DebugHelper.logError('Failed to upload image: $e');
//       throw Exception('Failed to upload image: $e');
//     }
//   }

//   // ENHANCED UTILITY METHODS

//   // Get category statistics
//   Map<String, dynamic> getCategoryStatistics() {
//     final mainCategories = getMainCategories();
//     int totalSubCategories = 0;
//     int totalProducts = 0;

//     for (final category in mainCategories) {
//       final subCats = getSubCategories(category['id']);
//       totalSubCategories += subCats.length;
//     }

//     // Count products per category
//     final categoryProductCounts = <String, int>{};
//     for (final product in _allProducts) {
//       final categoryId = product['category'] as String?;
//       if (categoryId != null) {
//         categoryProductCounts[categoryId] = (categoryProductCounts[categoryId] ?? 0) + 1;
//         totalProducts++;
//       }
//     }

//     return {
//       'mainCategories': mainCategories.length,
//       'totalSubCategories': totalSubCategories,
//       'totalProducts': totalProducts,
//       'categoryProductCounts': categoryProductCounts,
//       'averageProductsPerCategory': totalProducts / (mainCategories.length > 0 ? mainCategories.length : 1),
//     };
//   }

//   // Get user statistics
//   Map<String, dynamic> getUserStatistics() {
//     final individualUsers = _allUsers.where((user) => user['type'] == 'individual').length;
//     final companyUsers = _allUsers.where((user) => user['type'] == 'company').length;
//     final activeUsers = _allUsers.where((user) => user['isActive'] == true).length;

//     return {
//       'totalUsers': _totalUsers,
//       'individualUsers': individualUsers,
//       'companyUsers': companyUsers,
//       'activeUsers': activeUsers,
//       'inactiveUsers': _totalUsers - activeUsers,
//       'companyPercentage': _totalUsers > 0 ? (companyUsers / _totalUsers) * 100 : 0,
//     };
//   }

//   // Get product statistics
//   Map<String, dynamic> getProductStatistics() {
//     final activeProducts = _allProducts.where((product) => product['status'] == 'active').length;
//     final pendingProducts = _allProducts.where((product) => product['status'] == 'pending').length;
//     final inactiveProducts = _allProducts.where((product) => product['status'] == 'inactive').length;

//     // Calculate average price
//     double totalPrice = 0;
//     int priceCount = 0;
    
//     for (final product in _allProducts) {
//       final price = product['price'];
//       if (price != null && price is num) {
//         totalPrice += price.toDouble();
//         priceCount++;
//       }
//     }

//     final averagePrice = priceCount > 0 ? totalPrice / priceCount : 0;

//     return {
//       'totalProducts': _totalProducts,
//       'activeProducts': activeProducts,
//       'pendingProducts': pendingProducts,
//       'inactiveProducts': inactiveProducts,
//       'averagePrice': averagePrice,
//       'totalValue': totalPrice,
//     };
//   }

//   // Search functionality
//   List<Map<String, dynamic>> searchUsers(String query) {
//     if (query.isEmpty) return _allUsers;
    
//     final lowercaseQuery = query.toLowerCase();
//     return _allUsers.where((user) {
//       final email = (user['email'] as String? ?? '').toLowerCase();
//       final companyName = (user['companyName'] as String? ?? '').toLowerCase();
//       final phone = (user['phone'] as String? ?? '').toLowerCase();
      
//       return email.contains(lowercaseQuery) ||
//              companyName.contains(lowercaseQuery) ||
//              phone.contains(lowercaseQuery);
//     }).toList();
//   }

//   List<Map<String, dynamic>> searchProducts(String query) {
//     if (query.isEmpty) return _allProducts;
    
//     final lowercaseQuery = query.toLowerCase();
//     return _allProducts.where((product) {
//       final title = (product['itemTitle'] as String? ?? '').toLowerCase();
//       final description = (product['description'] as String? ?? '').toLowerCase();
//       final category = (product['categoryName'] as String? ?? '').toLowerCase();
//       final brand = (product['brand'] as String? ?? '').toLowerCase();
      
//       return title.contains(lowercaseQuery) ||
//              description.contains(lowercaseQuery) ||
//              category.contains(lowercaseQuery) ||
//              brand.contains(lowercaseQuery);
//     }).toList();
//   }

//   List<Map<String, dynamic>> searchCategories(String query) {
//     if (query.isEmpty) return _allCategories;
    
//     final lowercaseQuery = query.toLowerCase();
//     return _allCategories.where((category) {
//       final name = (category['name'] as String? ?? '').toLowerCase();
//       final description = (category['description'] as String? ?? '').toLowerCase();
      
//       return name.contains(lowercaseQuery) ||
//              description.contains(lowercaseQuery);
//     }).toList();
//   }

//   // Filter functionality
//   List<Map<String, dynamic>> filterProducts({
//     String? status,
//     String? category,
//     double? minPrice,
//     double? maxPrice,
//     DateTime? startDate,
//     DateTime? endDate,
//   }) {
//     return _allProducts.where((product) {
//       // Status filter
//       if (status != null && product['status'] != status) {
//         return false;
//       }
      
//       // Category filter
//       if (category != null && product['category'] != category) {
//         return false;
//       }
      
//       // Price filters
//       final price = product['price'] as num?;
//       if (price != null) {
//         if (minPrice != null && price < minPrice) return false;
//         if (maxPrice != null && price > maxPrice) return false;
//       }
      
//       // Date filters
//       final createdAt = product['createdAt'] as Timestamp?;
//       if (createdAt != null) {
//         final date = createdAt.toDate();
//         if (startDate != null && date.isBefore(startDate)) return false;
//         if (endDate != null && date.isAfter(endDate)) return false;
//       }
      
//       return true;
//     }).toList();
//   }

//   List<Map<String, dynamic>> filterUsers({
//     String? type,
//     bool? isActive,
//     DateTime? startDate,
//     DateTime? endDate,
//   }) {
//     return _allUsers.where((user) {
//       // Type filter
//       if (type != null && user['type'] != type) {
//         return false;
//       }
      
//       // Active filter
//       if (isActive != null && user['isActive'] != isActive) {
//         return false;
//       }
      
//       // Date filters
//       final createdAt = user['createdAt'] as Timestamp?;
//       if (createdAt != null) {
//         final date = createdAt.toDate();
//         if (startDate != null && date.isBefore(startDate)) return false;
//         if (endDate != null && date.isAfter(endDate)) return false;
//       }
      
//       return true;
//     }).toList();
//   }

//   // Utility methods
//   void clearError() {
//     _setError(null);
//   }

//   void clearAllData() {
//     _allUsers.clear();
//     _allProducts.clear();
//     _allCategories.clear();
//     _allBanners.clear();
//     _chatConversations.clear();
//     _supportRequests.clear();
//     _recentUsers.clear();
//     _recentProducts.clear();
//     _clearCache();
//     notifyListeners();
//   }

//   // UPDATED: Load both chat reports and account reports
//   Future<void> loadAllReports() async {
//     if (_isLoading) return;
    
//     setLoading(true);
//     try {
//       // Load chat reports and account reports in parallel
//       final results = await Future.wait([
//         _loadChatReports(),
//         _loadAccountReports(),
//       ]);
      
//       _allChatReports = results[0];
//       _allAccountReports = results[1];
      
//       _updateLastUpdated();
//       log('✅ Loaded ${_allChatReports.length} chat reports and ${_allAccountReports.length} account reports');
      
//     } catch (e) {
//       log('❌ Error loading reports: $e');
//       _setError('Failed to load reports: $e');
//     }
//   }

//   // NEW: Load chat reports from 'reports' collection
//   Future<List<Map<String, dynamic>>> _loadChatReports() async {
//     try {
//       final reportsSnapshot = await _firestore
//           .collection('reports')
//           .orderBy('createdAt', descending: true)
//           .get();

//       return reportsSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         data['reportType'] = 'chat'; // Mark as chat report
//         data['collection'] = 'reports'; // Store original collection
//         return data;
//       }).toList();
//     } catch (e) {
//       log('❌ Error loading chat reports: $e');
//       return [];
//     }
//   }

//   // NEW: Load account reports from 'account_reports' collection
//   Future<List<Map<String, dynamic>>> _loadAccountReports() async {
//     try {
//       final reportsSnapshot = await _firestore
//           .collection('account_reports')
//           .orderBy('createdAt', descending: true)
//           .get();

//       return reportsSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         data['reportType'] = 'user'; // Mark as user/account report
//         data['collection'] = 'account_reports'; // Store original collection
//         return data;
//       }).toList();
//     } catch (e) {
//       log('❌ Error loading account reports: $e');
//       return [];
//     }
//   }

//   // UPDATED: Update report status for both types
//   Future<void> updateReportStatus(Map<String, dynamic> report, String status, {String? adminNotes}) async {
//     try {
//       final reportId = report['id'] ?? report['reportId'];
//       final collection = report['collection'] ?? 'reports';
      
//       if (reportId == null) {
//         throw Exception('Report ID is required');
//       }

//       Map<String, dynamic> updateData = {
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       };

//       if (adminNotes != null) {
//         updateData['adminNotes'] = adminNotes;
//         updateData['reviewedAt'] = FieldValue.serverTimestamp();
//       }

//       await _firestore.collection(collection).doc(reportId).update(updateData);
      
//       // Update local data
//       if (collection == 'reports') {
//         final reportIndex = _allChatReports.indexWhere((r) => r['id'] == reportId);
//         if (reportIndex != -1) {
//           _allChatReports[reportIndex]['status'] = status;
//           if (adminNotes != null) {
//             _allChatReports[reportIndex]['adminNotes'] = adminNotes;
//           }
//         }
//       } else if (collection == 'account_reports') {
//         final reportIndex = _allAccountReports.indexWhere((r) => r['id'] == reportId);
//         if (reportIndex != -1) {
//           _allAccountReports[reportIndex]['status'] = status;
//           if (adminNotes != null) {
//             _allAccountReports[reportIndex]['adminNotes'] = adminNotes;
//           }
//         }
//       }
      
//       _updateLastUpdated();
//       notifyListeners();
      
//       log('✅ Updated ${collection} report status: $reportId -> $status');
      
//     } catch (e) {
//       log('❌ Error updating report status: $e');
//       _setError('Failed to update report status: $e');
//     }
//   }

//   // UPDATED: Delete report from appropriate collection
//   Future<void> deleteReport(Map<String, dynamic> report) async {
//     try {
//       final reportId = report['id'] ?? report['reportId'];
//       final collection = report['collection'] ?? 'reports';
      
//       if (reportId == null) {
//         throw Exception('Report ID is required');
//       }

//       await _firestore.collection(collection).doc(reportId).delete();
      
//       // Remove from local data
//       if (collection == 'reports') {
//         _allChatReports.removeWhere((r) => r['id'] == reportId);
//       } else if (collection == 'account_reports') {
//         _allAccountReports.removeWhere((r) => r['id'] == reportId);
//       }
      
//       _updateLastUpdated();
//       notifyListeners();
      
//       log('✅ Deleted ${collection} report: $reportId');
      
//     } catch (e) {
//       log('❌ Error deleting report: $e');
//       _setError('Failed to delete report: $e');
//     }
//   }

//   // Get user details for reports
//   Future<Map<String, dynamic>?> getUserDetails(String userId) async {
//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       if (userDoc.exists) {
//         Map<String, dynamic> userData = userDoc.data()!;
//         userData['id'] = userDoc.id;
//         return userData;
//       }
//       return null;
//     } catch (e) {
//       log('❌ Error getting user details: $e');
//       return null;
//     }
//   }

//   // UPDATED: Filter reports with support for both types
//   List<Map<String, dynamic>> filterReports({
//     List<Map<String, dynamic>>? reports,
//     String? status,
//     String? reason,
//     String? type,
//     DateTime? startDate,
//     DateTime? endDate,
//   }) {
//     final reportsToFilter = reports ?? allReports;
    
//     return reportsToFilter.where((report) {
//       // Status filter
//       if (status != null && report['status'] != status) {
//         return false;
//       }
      
//       // Reason filter (handle both chat and account report reason fields)
//       if (reason != null) {
//         final reportReason = report['reportReason'] ?? report['reason'];
//         if (reportReason != reason) {
//           return false;
//         }
//       }
      
//       // Type filter
//       if (type != null) {
//         final reportType = report['reportType'];
//         if (type == 'user' && reportType != 'user') {
//           return false;
//         } else if (type == 'message' && reportType != 'chat') {
//           return false;
//         }
//       }
      
//       // Date filters
//       final createdAt = report['createdAt'] as Timestamp?;
//       if (createdAt != null) {
//         final date = createdAt.toDate();
//         if (startDate != null && date.isBefore(startDate)) return false;
//         if (endDate != null && date.isAfter(endDate)) return false;
//       }
      
//       return true;
//     }).toList();
//   }

//   // UPDATED: Search reports with support for both types
//   List<Map<String, dynamic>> searchReports(String query) {
//     if (query.isEmpty) return allReports;
    
//     final lowercaseQuery = query.toLowerCase();
//     return allReports.where((report) {
//       // Handle both chat and account report fields
//       final reason = (report['reportReason'] as String? ?? report['reason'] as String? ?? '').toLowerCase();
//       final details = (report['additionalComments'] as String? ?? report['details'] as String? ?? '').toLowerCase();
//       final reportedUserId = (report['reportedUserId'] as String? ?? '').toLowerCase();
//       final reportedBy = (report['reporterId'] as String? ?? report['reportedBy'] as String? ?? '').toLowerCase();
//       final reportedUserName = (report['reportedUserName'] as String? ?? '').toLowerCase();
      
//       return reason.contains(lowercaseQuery) ||
//              details.contains(lowercaseQuery) ||
//              reportedUserId.contains(lowercaseQuery) ||
//              reportedBy.contains(lowercaseQuery) ||
//              reportedUserName.contains(lowercaseQuery);
//     }).toList();
//   }

//   // NEW: Get report statistics
//   Map<String, dynamic> getReportStatistics() {
//     final allReportsList = allReports;
    
//     // Count by status
//     final statusCounts = <String, int>{};
//     final typeCounts = <String, int>{};
//     final reasonCounts = <String, int>{};
    
//     for (final report in allReportsList) {
//       final status = report['status'] ?? 'pending';
//       final type = report['reportType'] ?? 'unknown';
//       final reason = report['reportReason'] ?? report['reason'] ?? 'unknown';
      
//       statusCounts[status] = (statusCounts[status] ?? 0) + 1;
//       typeCounts[type] = (typeCounts[type] ?? 0) + 1;
//       reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
//     }
    
//     return {
//       'total': allReportsList.length,
//       'chatReports': _allChatReports.length,
//       'accountReports': _allAccountReports.length,
//       'statusCounts': statusCounts,
//       'typeCounts': typeCounts,
//       'reasonCounts': reasonCounts,
//     };
//   }

//   // NEW: Get recent reports (last 24 hours)
//   List<Map<String, dynamic>> getRecentReports() {
//     final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
//     return allReports.where((report) {
//       final createdAt = report['createdAt'] as Timestamp?;
//       if (createdAt == null) return false;
      
//       return createdAt.toDate().isAfter(yesterday);
//     }).toList();
//   }

//   // NEW: Get reports by user
//   List<Map<String, dynamic>> getReportsByUser(String userId) {
//     return allReports.where((report) {
//       final reportedUserId = report['reportedUserId'] as String?;
//       final reporterId = report['reporterId'] as String? ?? report['reportedBy'] as String?;
      
//       return reportedUserId == userId || reporterId == userId;
//     }).toList();
//   }

//   // NEW: Bulk update report status
//   Future<void> bulkUpdateReportStatus(List<Map<String, dynamic>> reports, String status, {String? adminNotes}) async {
//     try {
//       // Group reports by collection
//       final chatReports = reports.where((r) => r['collection'] == 'reports').toList();
//       final accountReports = reports.where((r) => r['collection'] == 'account_reports').toList();
      
//       // Update in batches
//       final batch = _firestore.batch();
      
//       Map<String, dynamic> updateData = {
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       };
      
//       if (adminNotes != null) {
//         updateData['adminNotes'] = adminNotes;
//         updateData['reviewedAt'] = FieldValue.serverTimestamp();
//       }
      
//       // Add chat reports to batch
//       for (final report in chatReports) {
//         final reportId = report['id'] ?? report['reportId'];
//         if (reportId != null) {
//           batch.update(_firestore.collection('reports').doc(reportId), updateData);
//         }
//       }
      
//       // Add account reports to batch
//       for (final report in accountReports) {
//         final reportId = report['id'] ?? report['reportId'];
//         if (reportId != null) {
//           batch.update(_firestore.collection('account_reports').doc(reportId), updateData);
//         }
//       }
      
//       await batch.commit();
      
//       // Update local data
//       for (final report in reports) {
//         report['status'] = status;
//         if (adminNotes != null) {
//           report['adminNotes'] = adminNotes;
//         }
//       }
      
//       _updateLastUpdated();
//       notifyListeners();
      
//       log('✅ Bulk updated ${reports.length} reports to status: $status');
      
//     } catch (e) {
//       log('❌ Error bulk updating reports: $e');
//       _setError('Failed to bulk update reports: $e');
//     }
//   }

//   // NEW: Clear all reports data
//   void clearReportsData() {
//     _allChatReports.clear();
//     _allAccountReports.clear();
//     notifyListeners();
//   }
// }


// // Updated AdminDataProvider methods for category management
// extension CategoryFieldConfigExtension on AdminDataProvider {
  
  
//   // Create category with field configuration
//   Future<void> createCategoryWithFields(Map<String, dynamic> categoryData) async {
//     try {
//       setLoading(true);
      
//       final docRef = await _firestore.collection('categories').add({
//         ...categoryData,
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
      
//       // If this category has field configuration, also create a separate document
//       // for quick field lookup during product creation
//       if (categoryData['hasCustomFields'] == true) {
//         await _firestore
//             .collection('category_field_configs')
//             .doc(docRef.id)
//             .set({
//           'categoryId': docRef.id,
//           'categoryName': categoryData['name'],
//           'fieldTemplate': categoryData['fieldTemplate'],
//           'inheritedTemplates': categoryData['inheritedTemplates'],
//           'configuredFields': categoryData['configuredFields'],
//           'level': categoryData['level'],
//           'parentId': categoryData['parentId'],
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//       }
      
//       await loadAllCategories(); // Refresh categories
//       setLoading(false);
      
//     } catch (e) {
//       // setError('Failed to create category: $e');
//       setLoading(false);
//       rethrow;
//     }
//   }
  
//   // Get field configuration for a category
//   Future<Map<String, dynamic>?> getCategoryFieldConfig(String categoryId) async {
//     try {
//       final doc = await _firestore
//           .collection('category_field_configs')
//           .doc(categoryId)
//           .get();
      
//       if (doc.exists) {
//         return doc.data();
//       }
      
//       // Fallback: get from main category document
//       final categoryDoc = await _firestore
//           .collection('categories')
//           .doc(categoryId)
//           .get();
      
//       if (categoryDoc.exists) {
//         final data = categoryDoc.data()!;
//         if (data['hasCustomFields'] == true) {
//           return {
//             'categoryId': categoryId,
//             'categoryName': data['name'],
//             'fieldTemplate': data['fieldTemplate'],
//             'inheritedTemplates': data['inheritedTemplates'],
//             'configuredFields': data['configuredFields'],
//             'level': data['level'],
//             'parentId': data['parentId'],
//           };
//         }
//       }
      
//       return null;
//     } catch (e) {
//       log('Error getting category field config: $e');
//       return null;
//     }
//   }
  
//   // Get all configured fields for a category (including inherited)
//   Future<List<Map<String, dynamic>>> getAllFieldsForCategory(String categoryId) async {
//     try {
//       final config = await getCategoryFieldConfig(categoryId);
//       if (config == null) return [];
      
//       final fieldTemplate = config['fieldTemplate'] as String?;
//       final inheritedTemplates = List<String>.from(config['inheritedTemplates'] ?? []);
      
//       if (fieldTemplate != null) {
//         return CategoryFieldTemplates.getFieldsForCategory(
//           fieldTemplate,
//           parentTemplateIds: inheritedTemplates,
//           allTemplates: _allTemplates,
//         );
//       }
      
//       return [];
//     } catch (e) {
//       log('Error getting all fields for category: $e');
//       return [];
//     }
//   }
// }
// extension ReportsManagementExtension on AdminDataProvider {
 

// }
// extension DynamicTemplateExtension on AdminDataProvider {
//   // Load all field templates from Firestore
//   Future<void> loadAllTemplates() async {
//     if (_isLoading) return;
    
//     setLoading(true);
//     try {
//       final templatesSnapshot = await _firestore
//           .collection('field_templates')
//           .orderBy('createdAt', descending: true)
//           .get();

//       _allTemplates = templatesSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
      
//       DebugHelper.logInfo('Loaded ${_allTemplates.length} field templates');
//       _updateLastUpdated();
//     } catch (e) {
//       DebugHelper.logError('Error loading field templates: $e');
//       _setError('Failed to load field templates: $e');
//     }
//     setLoading(false);
//   }

//   // Create new field template
//   Future<void> createFieldTemplate(Map<String, dynamic> templateData) async {
//     setLoading(true);
//     try {
//       final docRef = await _firestore.collection('field_templates').add({
//         ...templateData,
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       templateData['id'] = docRef.id;
//       templateData['createdAt'] = Timestamp.now();
//       _allTemplates.insert(0, templateData);
      
//       _updateLastUpdated();
//       notifyListeners();
      
//       DebugHelper.logInfo('Created field template: ${templateData['name']}');
//     } catch (e) {
//       DebugHelper.logError('Error creating field template: $e');
//       _setError('Failed to create field template: $e');
//       rethrow;
//     }
//     setLoading(false);
//   }

//   // Update field template
//   Future<void> updateFieldTemplate(String templateId, Map<String, dynamic> templateData) async {
//     setLoading(true);
//     try {
//       await _firestore.collection('field_templates').doc(templateId).update({
//         ...templateData,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       final templateIndex = _allTemplates.indexWhere((template) => template['id'] == templateId);
//       if (templateIndex != -1) {
//         _allTemplates[templateIndex] = {
//           ..._allTemplates[templateIndex],
//           ...templateData,
//           'id': templateId,
//           'updatedAt': Timestamp.now(),
//         };
        
//         _updateLastUpdated();
//         notifyListeners();
//       }
      
//       DebugHelper.logInfo('Updated field template: $templateId');
//     } catch (e) {
//       DebugHelper.logError('Error updating field template: $e');
//       _setError('Failed to update field template: $e');
//       rethrow;
//     }
//     setLoading(false);
//   }

//   // Delete field template
//   Future<void> deleteFieldTemplate(String templateId) async {
//     try {
//       // Check if template is being used by any categories
//       final categoriesSnapshot = await _firestore
//           .collection('categories')
//           .where('fieldTemplate', isEqualTo: templateId)
//           .limit(1)
//           .get();
      
//       if (categoriesSnapshot.docs.isNotEmpty) {
//         throw Exception('Cannot delete template that is being used by categories. Please update those categories first.');
//       }

//       await _firestore.collection('field_templates').doc(templateId).delete();
      
//       _allTemplates.removeWhere((template) => template['id'] == templateId);
//       _updateLastUpdated();
//       notifyListeners();
      
//       DebugHelper.logInfo('Deleted field template: $templateId');
//     } catch (e) {
//       DebugHelper.logError('Error deleting field template: $e');
//       _setError('Failed to delete field template: $e');
//       rethrow;
//     }
//   }

//   // Get template by ID
//   Map<String, dynamic>? getTemplateById(String templateId) {
//     try {
//       return _allTemplates.firstWhere(
//         (template) => template['id'] == templateId,
//         orElse: () => <String, dynamic>{},
//       );
//     } catch (e) {
//       DebugHelper.logError('Error getting template by ID: $e');
//       return null;
//     }
//   }

//   // Get templates by category (for inheritance)
//   List<Map<String, dynamic>> getTemplatesByIds(List<String> templateIds) {
//     return _allTemplates.where((template) => templateIds.contains(template['id'])).toList();
//   }

//   // Search templates
//   List<Map<String, dynamic>> searchTemplates(String query) {
//     if (query.isEmpty) return _allTemplates;
    
//     final lowercaseQuery = query.toLowerCase();
//     return _allTemplates.where((template) {
//       final name = (template['name'] as String? ?? '').toLowerCase();
//       final description = (template['description'] as String? ?? '').toLowerCase();
//       final category = (template['category'] as String? ?? '').toLowerCase();
      
//       return name.contains(lowercaseQuery) ||
//              description.contains(lowercaseQuery) ||
//              category.contains(lowercaseQuery);
//     }).toList();
//   }

//   // Get template usage count
//   Future<int> getTemplateUsageCount(String templateId) async {
//     try {
//       final categoriesSnapshot = await _firestore
//           .collection('categories')
//           .where('fieldTemplate', isEqualTo: templateId)
//           .get();
      
//       return categoriesSnapshot.docs.length;
//     } catch (e) {
//       DebugHelper.logError('Error getting template usage count: $e');
//       return 0;
//     }
//   }
// }
