// reports_provider.dart
import 'package:delloniweb/model/seller_model.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'base_admin_provider.dart';
class ReportsProvider extends BaseAdminProvider {
  // Reports data
  List<Map<String, dynamic>> _allChatReports = [];
  List<Map<String, dynamic>> _allAccountReports = [];

  // Getters
  List<Map<String, dynamic>> get allChatReports => _allChatReports;
  List<Map<String, dynamic>> get allAccountReports => _allAccountReports;
  
  // Combined getter for backward compatibility
  List<Map<String, dynamic>> get allReports => [..._allChatReports, ..._allAccountReports];

  // LOAD REPORTS DATA

  Future<void> loadAllReports() async {
    if (isLoading) return;
    
    setLoading(true);
    try {
      // Load chat reports and account reports in parallel
      final results = await Future.wait([
        _loadChatReports(),
        _loadAccountReports(),
      ]);
      
      _allChatReports = results[0];
      _allAccountReports = results[1];
      
      updateLastUpdated();
      notifyListeners();
      
      DebugHelper.logInfo('✅ Loaded ${_allChatReports.length} chat reports and ${_allAccountReports.length} account reports');
      
    } catch (e) {
      DebugHelper.logError('❌ Error loading reports: $e');
      setError('Failed to load reports: $e');
    }
    setLoading(false);
  }

  // Load chat reports from 'chat_reports' collection
  Future<List<Map<String, dynamic>>> _loadChatReports() async {
    try {
      final reportsSnapshot = await firestore
          .collection('chat_reports') // Fixed: Use 'chat_reports' collection
          .orderBy('reportedAt', descending: true) // Fixed: Use 'reportedAt' field
          .get();

      List<Map<String, dynamic>> chatReports = [];
      
      for (var doc in reportsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        data['reportType'] = 'chat'; // Mark as chat report
        data['collection'] = 'chat_reports'; // Store original collection
        
        // Map fields to match the UI expectations
        data['createdAt'] = data['reportedAt']; // Map reportedAt to createdAt for UI consistency
        data['reportReason'] = data['reason']; // Map reason to reportReason for UI consistency
        data['reporterId'] = data['reportedBy']; // Map reportedBy to reporterId for UI consistency
        
        // Extract reported user info from participants
        if (data['participants'] != null && data['participants'] is List) {
          final participants = data['participants'] as List;
          final reportedBy = data['reportedBy'] as String?;
          
          // The reported user is the participant who is not the reporter
          final reportedUserId = participants.firstWhere(
            (participant) => participant != reportedBy,
            orElse: () => participants.isNotEmpty ? participants[0] : '',
          );
          
          data['reportedUserId'] = reportedUserId;
          
          // Initialize with user ID, will be enriched later with actual user details
          data['reportedUserName'] = 'Loading...';
        }
        
        // Set default values for missing fields
        data['additionalComments'] = data['details'] ?? '';
        data['status'] = data['status'] ?? 'pending';
        
        chatReports.add(data);
      }
      
      // Enrich with user details
      await _enrichReportsWithUserDetails(chatReports);
      
      return chatReports;
    } catch (e) {
      DebugHelper.logError('❌ Error loading chat reports: $e');
      return [];
    }
  }

  // Load account reports from 'account_reports' collection
  Future<List<Map<String, dynamic>>> _loadAccountReports() async {
    try {
      final reportsSnapshot = await firestore
          .collection('account_reports')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> accountReports = reportsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        data['reportType'] = 'user'; // Mark as user/account report
        data['collection'] = 'account_reports'; // Store original collection
        return data;
      }).toList();

      // Enrich with user details
      await _enrichReportsWithUserDetails(accountReports);

      return accountReports;
    } catch (e) {
      DebugHelper.logError('❌ Error loading account reports: $e');
      return [];
    }
  }

  // ENHANCED: Load user details for reports using SellerModel
  Future<void> _enrichReportsWithUserDetails(List<Map<String, dynamic>> reports) async {
    try {
      for (var report in reports) {
        final reportedUserId = report['reportedUserId'] as String?;
        final reporterId = report['reporterId'] as String?;
        
        // Enrich reported user details
        if (reportedUserId != null && reportedUserId.isNotEmpty) {
          final reportedUser = await getUserDetailsBySellerId(reportedUserId);
          if (reportedUser != null) {
            report['reportedUserName'] = reportedUser.getDisplayName();
            report['reportedUserEmail'] = reportedUser.email;
            report['reportedUserPhone'] = reportedUser.phone;
            report['reportedUserType'] = reportedUser.type;
            report['reportedUserProfileImage'] = reportedUser.profileImageUrl;
            report['reportedUserVerified'] = reportedUser.isVerified;
            report['reportedUserOnline'] = reportedUser.isOnline;
            report['reportedUserRating'] = reportedUser.rating;
            report['reportedUserReviewCount'] = reportedUser.reviewCount;
            report['reportedUserTotalAds'] = reportedUser.totalAds;
            report['reportedUserMemberSince'] = reportedUser.memberSince;
            report['reportedUserLastSeen'] = reportedUser.lastSeen;
            report['reportedUserAddress'] = reportedUser.address;
            report['reportedUserCompanyName'] = reportedUser.companyName;
          } else {
            report['reportedUserName'] = 'User Not Found';
          }
        }
        
        // Enrich reporter details
        if (reporterId != null && reporterId.isNotEmpty) {
          final reporter = await getUserDetailsBySellerId(reporterId);
          if (reporter != null) {
            report['reporterName'] = reporter.getDisplayName();
            report['reporterEmail'] = reporter.email;
            report['reporterType'] = reporter.type;
            report['reporterVerified'] = reporter.isVerified;
          } else {
            report['reporterName'] = 'User Not Found';
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      DebugHelper.logError('❌ Error enriching reports with user details: $e');
    }
  }

  // REPORT MANAGEMENT OPERATIONS

  Future<void> updateReportStatus(Map<String, dynamic> report, String status, {String? adminNotes}) async {
    try {
      final reportId = report['id'] ?? report['reportId'];
      final collection = report['collection'] ?? 'chat_reports'; // Default to chat_reports
      
      if (reportId == null) {
        throw Exception('Report ID is required');
      }

      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
        updateData['reviewedAt'] = FieldValue.serverTimestamp();
      }

      await firestore.collection(collection).doc(reportId).update(updateData);
      
      // Update local data
      if (collection == 'chat_reports') {
        final reportIndex = _allChatReports.indexWhere((r) => r['id'] == reportId);
        if (reportIndex != -1) {
          _allChatReports[reportIndex]['status'] = status;
          if (adminNotes != null) {
            _allChatReports[reportIndex]['adminNotes'] = adminNotes;
            _allChatReports[reportIndex]['reviewedAt'] = Timestamp.now();
          }
        }
      } else if (collection == 'account_reports') {
        final reportIndex = _allAccountReports.indexWhere((r) => r['id'] == reportId);
        if (reportIndex != -1) {
          _allAccountReports[reportIndex]['status'] = status;
          if (adminNotes != null) {
            _allAccountReports[reportIndex]['adminNotes'] = adminNotes;
            _allAccountReports[reportIndex]['reviewedAt'] = Timestamp.now();
          }
        }
      }
      
      updateLastUpdated();
      notifyListeners();
      
      // Log admin action
      await logAdminAction('update_report_status', reportId, 'Report status updated to: $status', targetType: 'report');
      
      DebugHelper.logInfo('✅ Updated ${collection} report status: $reportId -> $status');
      
    } catch (e) {
      DebugHelper.logError('❌ Error updating report status: $e');
      setError('Failed to update report status: $e');
      rethrow;
    }
  }

  Future<void> deleteReport(Map<String, dynamic> report) async {
    try {
      final reportId = report['id'] ?? report['reportId'];
      final collection = report['collection'] ?? 'chat_reports'; // Default to chat_reports
      
      if (reportId == null) {
        throw Exception('Report ID is required');
      }

      await firestore.collection(collection).doc(reportId).delete();
      
      // Remove from local data
      if (collection == 'chat_reports') {
        _allChatReports.removeWhere((r) => r['id'] == reportId);
      } else if (collection == 'account_reports') {
        _allAccountReports.removeWhere((r) => r['id'] == reportId);
      }
      
      updateLastUpdated();
      notifyListeners();
      
      // Log admin action
      await logAdminAction('delete_report', reportId, 'Report deleted', targetType: 'report');
      
      DebugHelper.logInfo('✅ Deleted ${collection} report: $reportId');
      
    } catch (e) {
      DebugHelper.logError('❌ Error deleting report: $e');
      setError('Failed to delete report: $e');
      rethrow;
    }
  }

  // BULK OPERATIONS

  Future<void> bulkUpdateReportStatus(List<Map<String, dynamic>> reports, String status, {String? adminNotes}) async {
    try {
      // Group reports by collection
      final chatReports = reports.where((r) => r['collection'] == 'chat_reports').toList();
      final accountReports = reports.where((r) => r['collection'] == 'account_reports').toList();
      
      // Update in batches
      final batch = firestore.batch();
      
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
        updateData['reviewedAt'] = FieldValue.serverTimestamp();
      }
      
      // Add chat reports to batch
      for (final report in chatReports) {
        final reportId = report['id'] ?? report['reportId'];
        if (reportId != null) {
          batch.update(firestore.collection('chat_reports').doc(reportId), updateData);
        }
      }
      
      // Add account reports to batch
      for (final report in accountReports) {
        final reportId = report['id'] ?? report['reportId'];
        if (reportId != null) {
          batch.update(firestore.collection('account_reports').doc(reportId), updateData);
        }
      }
      
      await batch.commit();
      
      // Update local data
      for (final report in reports) {
        report['status'] = status;
        if (adminNotes != null) {
          report['adminNotes'] = adminNotes;
          report['reviewedAt'] = Timestamp.now();
        }
      }
      
      updateLastUpdated();
      notifyListeners();
      
      // Log admin action
      await logAdminAction('bulk_update_reports', '${reports.length}_reports', 'Bulk updated ${reports.length} reports to status: $status', targetType: 'report');
      
      DebugHelper.logInfo('✅ Bulk updated ${reports.length} reports to status: $status');
      
    } catch (e) {
      DebugHelper.logError('❌ Error bulk updating reports: $e');
      setError('Failed to bulk update reports: $e');
      rethrow;
    }
  }

  Future<void> bulkDeleteReports(List<Map<String, dynamic>> reports) async {
    try {
      // Group reports by collection
      final chatReports = reports.where((r) => r['collection'] == 'chat_reports').toList();
      final accountReports = reports.where((r) => r['collection'] == 'account_reports').toList();
      
      // Delete in batches
      final batch = firestore.batch();
      
      // Add chat reports to batch
      for (final report in chatReports) {
        final reportId = report['id'] ?? report['reportId'];
        if (reportId != null) {
          batch.delete(firestore.collection('chat_reports').doc(reportId));
        }
      }
      
      // Add account reports to batch
      for (final report in accountReports) {
        final reportId = report['id'] ?? report['reportId'];
        if (reportId != null) {
          batch.delete(firestore.collection('account_reports').doc(reportId));
        }
      }
      
      await batch.commit();
      
      // Remove from local data
      final reportIds = reports.map((r) => r['id'] ?? r['reportId']).where((id) => id != null).toList();
      _allChatReports.removeWhere((r) => reportIds.contains(r['id']));
      _allAccountReports.removeWhere((r) => reportIds.contains(r['id']));
      
      updateLastUpdated();
      notifyListeners();
      
      // Log admin action
      await logAdminAction('bulk_delete_reports', '${reports.length}_reports', 'Bulk deleted ${reports.length} reports', targetType: 'report');
      
      DebugHelper.logInfo('✅ Bulk deleted ${reports.length} reports');
      
    } catch (e) {
      DebugHelper.logError('❌ Error bulk deleting reports: $e');
      setError('Failed to bulk delete reports: $e');
      rethrow;
    }
  }

  // UTILITY METHODS

  Future<SellerModel?> getUserDetailsBySellerId(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return SellerModel.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      DebugHelper.logError('❌ Error getting user details by seller ID: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data()!;
        userData['id'] = userDoc.id;
        return userData;
      }
      return null;
    } catch (e) {
      DebugHelper.logError('❌ Error getting user details: $e');
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
      DebugHelper.logError('❌ Error getting chat details: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMessageDetails(String chatId, String messageId) async {
    try {
      final messageDoc = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();
      
      if (messageDoc.exists) {
        Map<String, dynamic> messageData = messageDoc.data()!;
        messageData['id'] = messageDoc.id;
        return messageData;
      }
      return null;
    } catch (e) {
      DebugHelper.logError('❌ Error getting message details: $e');
      return null;
    }
  }

  // SEARCH AND FILTER

  List<Map<String, dynamic>> filterReports({
    List<Map<String, dynamic>>? reports,
    String? status,
    String? reason,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final reportsToFilter = reports ?? allReports;
    
    return reportsToFilter.where((report) {
      // Status filter
      if (status != null && report['status'] != status) {
        return false;
      }
      
      // Reason filter (handle both chat and account report reason fields)
      if (reason != null) {
        final reportReason = report['reportReason'] ?? report['reason'];
        if (reportReason != reason) {
          return false;
        }
      }
      
      // Type filter
      if (type != null) {
        final reportType = report['reportType'];
        if (type == 'user' && reportType != 'user') {
          return false;
        } else if (type == 'message' && reportType != 'chat') {
          return false;
        }
      }
      
      // Date filters - check both createdAt and reportedAt
      final createdAt = report['createdAt'] as Timestamp? ?? report['reportedAt'] as Timestamp?;
      if (createdAt != null) {
        final date = createdAt.toDate();
        if (startDate != null && date.isBefore(startDate)) return false;
        if (endDate != null && date.isAfter(endDate)) return false;
      }
      
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> searchReports(String query) {
    if (query.isEmpty) return allReports;
    
    final lowercaseQuery = query.toLowerCase();
    return allReports.where((report) {
      // Handle both chat and account report fields
      final reason = (report['reportReason'] as String? ?? report['reason'] as String? ?? '').toLowerCase();
      final details = (report['additionalComments'] as String? ?? report['details'] as String? ?? '').toLowerCase();
      final reportedUserId = (report['reportedUserId'] as String? ?? '').toLowerCase();
      final reportedBy = (report['reporterId'] as String? ?? report['reportedBy'] as String? ?? '').toLowerCase();
      final reportedUserName = (report['reportedUserName'] as String? ?? '').toLowerCase();
      final adminNotes = (report['adminNotes'] as String? ?? '').toLowerCase();
      final chatId = (report['chatId'] as String? ?? '').toLowerCase();
      
      return reason.contains(lowercaseQuery) ||
             details.contains(lowercaseQuery) ||
             reportedUserId.contains(lowercaseQuery) ||
             reportedBy.contains(lowercaseQuery) ||
             reportedUserName.contains(lowercaseQuery) ||
             adminNotes.contains(lowercaseQuery) ||
             chatId.contains(lowercaseQuery);
    }).toList();
  }

  // STATISTICS AND ANALYTICS

  Map<String, dynamic> getReportStatistics() {
    final allReportsList = allReports;
    
    // Count by status
    final statusCounts = <String, int>{};
    final typeCounts = <String, int>{};
    final reasonCounts = <String, int>{};
    
    for (final report in allReportsList) {
      final status = report['status'] ?? 'pending';
      final type = report['reportType'] ?? 'unknown';
      final reason = report['reportReason'] ?? report['reason'] ?? 'unknown';
      
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
    }
    
    return {
      'total': allReportsList.length,
      'chatReports': _allChatReports.length,
      'accountReports': _allAccountReports.length,
      'statusCounts': statusCounts,
      'typeCounts': typeCounts,
      'reasonCounts': reasonCounts,
      'pendingReports': statusCounts['pending'] ?? 0,
      'resolvedReports': statusCounts['resolved'] ?? 0,
      'rejectedReports': statusCounts['rejected'] ?? 0,
    };
  }

  List<Map<String, dynamic>> getRecentReports() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    return allReports.where((report) {
      final createdAt = report['createdAt'] as Timestamp? ?? report['reportedAt'] as Timestamp?;
      if (createdAt == null) return false;
      
      return createdAt.toDate().isAfter(yesterday);
    }).toList();
  }

  List<Map<String, dynamic>> getReportsByUser(String userId) {
    return allReports.where((report) {
      final reportedUserId = report['reportedUserId'] as String?;
      final reporterId = report['reporterId'] as String? ?? report['reportedBy'] as String?;
      
      return reportedUserId == userId || reporterId == userId;
    }).toList();
  }

  List<Map<String, dynamic>> getPendingReports() {
    return allReports.where((report) => report['status'] == 'pending' || report['status'] == null).toList();
  }

  List<Map<String, dynamic>> getHighPriorityReports() {
    // Define high priority criteria
    return allReports.where((report) {
      final reason = report['reportReason'] ?? report['reason'];
      final highPriorityReasons = ['harassment', 'threats', 'spam', 'inappropriate_content'];
      
      return highPriorityReasons.contains(reason) && 
             (report['status'] == 'pending' || report['status'] == null);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> getReportsByReason() {
    final reportsByReason = <String, List<Map<String, dynamic>>>{};
    
    for (final report in allReports) {
      final reason = report['reportReason'] ?? report['reason'] ?? 'unknown';
      if (!reportsByReason.containsKey(reason)) {
        reportsByReason[reason] = [];
      }
      reportsByReason[reason]!.add(report);
    }
    
    return reportsByReason;
  }

  // EXPORT AND REPORTING

  Future<String> exportReportsData({
    List<Map<String, dynamic>>? reports,
    String format = 'csv',
  }) async {
    try {
      final reportsToExport = reports ?? allReports;
      
      if (format == 'csv') {
        final csv = StringBuffer();
        
        // CSV Headers
        csv.writeln('ID,Type,Reason,Status,Reported User,Reported By,Created At,Reviewed At,Admin Notes,Chat ID');
        
        // CSV Data
        for (final report in reportsToExport) {
          csv.writeln([
            report['id'] ?? '',
            report['reportType'] ?? '',
            report['reportReason'] ?? report['reason'] ?? '',
            report['status'] ?? 'pending',
            report['reportedUserId'] ?? '',
            report['reporterId'] ?? report['reportedBy'] ?? '',
            formatDate(report['createdAt'] ?? report['reportedAt']),
            formatDate(report['reviewedAt']),
            report['adminNotes'] ?? '',
            report['chatId'] ?? '',
          ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
        }
        
        return csv.toString();
      }
      
      return '';
      
    } catch (e) {
      DebugHelper.logError('Error exporting reports data: $e');
      rethrow;
    }
  }

  // REPORT ACTIONS

  Future<void> takeActionOnReportedUser(String userId, String action, {String? reason}) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      switch (action) {
        case 'warning':
          // Send warning notification
          await firestore.collection('notifications').add({
            'userId': userId,
            'title': 'Warning',
            'message': reason ?? 'You have received a warning from the administration.',
            'type': 'warning',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'sentBy': 'admin',
          });
          break;
        
        case 'suspend':
          updateData['isActive'] = false;
          updateData['suspendedAt'] = FieldValue.serverTimestamp();
          updateData['suspendedBy'] = 'admin';
          updateData['suspensionReason'] = reason;
          
          await firestore.collection('users').doc(userId).update(updateData);
          break;
        
        case 'ban':
          updateData['isActive'] = false;
          updateData['isBanned'] = true;
          updateData['bannedAt'] = FieldValue.serverTimestamp();
          updateData['bannedBy'] = 'admin';
          updateData['banReason'] = reason;
          
          await firestore.collection('users').doc(userId).update(updateData);
          break;
        
        case 'delete_content':
          // This would depend on what content to delete
          // Implementation specific to your needs
          break;
      }

      // Log admin action
      await logAdminAction('report_action_$action', userId, 'Action taken on reported user: $action', targetType: 'user');
      
    } catch (e) {
      DebugHelper.logError('❌ Error taking action on reported user: $e');
      setError('Failed to take action on reported user: $e');
      rethrow;
    }
  }

  // DATA MANAGEMENT

  void clearAllReportsData() {
    _allChatReports.clear();
    _allAccountReports.clear();
    notifyListeners();
  }

  // REFRESH DATA

  Future<void> refreshReports() async {
    await loadAllReports();
    // User details are now enriched automatically during loading
  }
}