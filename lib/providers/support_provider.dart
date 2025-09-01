// support_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_admin_provider.dart';

class SupportProvider extends BaseAdminProvider {
  // Support data
  List<Map<String, dynamic>> _supportRequests = [];
  int _pendingSupportRequests = 0;

  // Getters
  List<Map<String, dynamic>> get supportRequests => _supportRequests;
  int get pendingSupportRequests => _pendingSupportRequests;

  // LOAD SUPPORT DATA

  Future<void> loadSupportRequests() async {
    if (isLoading) return;
    
    setLoading(true);
    try {
      final supportSnapshot = await firestore
          .collection('contact_submissions')
          .orderBy('createdAt', descending: true)
          .get();

      _supportRequests = supportSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Update pending count
      _pendingSupportRequests = _supportRequests
          .where((request) => request['status'] == 'pending' || request['status'] == null)
          .length;
      
      updateLastUpdated();
      notifyListeners();
      
      DebugHelper.logInfo('Loaded ${_supportRequests.length} support requests from Firestore');
    } catch (e) {
      DebugHelper.logError('Error loading support requests: $e');
      setError('Failed to load support requests: $e');
    }
    setLoading(false);
  }

  Future<void> loadSupportStats() async {
    try {
      final supportSnapshot = await firestore
          .collection('contact_submissions')
          .where('status', isEqualTo: 'pending')
          .get();
      _pendingSupportRequests = supportSnapshot.docs.length;
      
      notifyListeners();
    } catch (e) {
      DebugHelper.logError('Error loading support stats: $e');
    }
  }

  // SUPPORT MANAGEMENT OPERATIONS

  Future<void> updateSupportRequestStatus(String requestId, String status, {String? response}) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (response != null) {
        updateData['adminResponse'] = response;
        updateData['responseDate'] = FieldValue.serverTimestamp();
        updateData['respondedBy'] = 'admin'; // Replace with actual admin ID
      }

      await firestore.collection('contact_submissions').doc(requestId).update(updateData);
      
      final requestIndex = _supportRequests.indexWhere((request) => request['id'] == requestId);
      if (requestIndex != -1) {
        _supportRequests[requestIndex]['status'] = status;
        _supportRequests[requestIndex]['updatedAt'] = Timestamp.now();
        if (response != null) {
          _supportRequests[requestIndex]['adminResponse'] = response;
          _supportRequests[requestIndex]['responseDate'] = Timestamp.now();
          _supportRequests[requestIndex]['respondedBy'] = 'admin';
        }
        
        // Update pending count
        _pendingSupportRequests = _supportRequests
            .where((request) => request['status'] == 'pending' || request['status'] == null)
            .length;
        
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction('update_support_status', requestId, 'Support request status updated to: $status', targetType: 'support');
      
      // Send notification to user if resolved
      if (status == 'resolved' && response != null) {
        final request = _supportRequests[requestIndex];
        final userId = request['userId'] as String?;
        if (userId != null) {
          await _sendResponseNotification(userId, request['subject'] ?? 'Your Support Request', response);
        }
      }
    } catch (e) {
      DebugHelper.logError('Error updating support request: $e');
      setError('Failed to update support request: $e');
      rethrow;
    }
  }

  Future<void> assignSupportRequest(String requestId, String assignedTo) async {
    try {
      await firestore.collection('contact_submissions').doc(requestId).update({
        'assignedTo': assignedTo,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final requestIndex = _supportRequests.indexWhere((request) => request['id'] == requestId);
      if (requestIndex != -1) {
        _supportRequests[requestIndex]['assignedTo'] = assignedTo;
        _supportRequests[requestIndex]['assignedAt'] = Timestamp.now();
        _supportRequests[requestIndex]['updatedAt'] = Timestamp.now();
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction('assign_support', requestId, 'Support request assigned to: $assignedTo', targetType: 'support');
    } catch (e) {
      DebugHelper.logError('Error assigning support request: $e');
      setError('Failed to assign support request: $e');
      rethrow;
    }
  }

  Future<void> addInternalNote(String requestId, String note) async {
    try {
      final request = _supportRequests.firstWhere((r) => r['id'] == requestId);
      final currentNotes = List<Map<String, dynamic>>.from(request['internalNotes'] ?? []);
      
      currentNotes.add({
        'note': note,
        'addedBy': 'admin', // Replace with actual admin ID
        'addedAt': Timestamp.now(),
      });

      await firestore.collection('contact_submissions').doc(requestId).update({
        'internalNotes': currentNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final requestIndex = _supportRequests.indexWhere((request) => request['id'] == requestId);
      if (requestIndex != -1) {
        _supportRequests[requestIndex]['internalNotes'] = currentNotes;
        _supportRequests[requestIndex]['updatedAt'] = Timestamp.now();
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction('add_support_note', requestId, 'Internal note added to support request', targetType: 'support');
    } catch (e) {
      DebugHelper.logError('Error adding internal note: $e');
      setError('Failed to add internal note: $e');
      rethrow;
    }
  }

  Future<void> _sendResponseNotification(String userId, String subject, String message) async {
    try {
      await firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Support Request Resolved: $subject',
        'message': message,
        'type': 'support_response',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'sentBy': 'admin',
      });
    } catch (e) {
      DebugHelper.logError('Error sending response notification: $e');
      // Don't throw error here as it's just notification
    }
  }

  // BULK OPERATIONS

  Future<void> bulkUpdateSupportStatus(List<String> requestIds, String status, {String? response}) async {
    try {
      final batch = firestore.batch();
      
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (response != null) {
        updateData['adminResponse'] = response;
        updateData['responseDate'] = FieldValue.serverTimestamp();
        updateData['respondedBy'] = 'admin';
      }
      
      for (final requestId in requestIds) {
        final requestRef = firestore.collection('contact_submissions').doc(requestId);
        batch.update(requestRef, updateData);
      }
      
      await batch.commit();
      
      // Update local data
      for (final requestId in requestIds) {
        final requestIndex = _supportRequests.indexWhere((request) => request['id'] == requestId);
        if (requestIndex != -1) {
          _supportRequests[requestIndex]['status'] = status;
          _supportRequests[requestIndex]['updatedAt'] = Timestamp.now();
          if (response != null) {
            _supportRequests[requestIndex]['adminResponse'] = response;
            _supportRequests[requestIndex]['responseDate'] = Timestamp.now();
            _supportRequests[requestIndex]['respondedBy'] = 'admin';
          }
        }
      }
      
      // Update pending count
      _pendingSupportRequests = _supportRequests
          .where((request) => request['status'] == 'pending' || request['status'] == null)
          .length;
      
      updateLastUpdated();
      notifyListeners();
      
      // Log bulk action
      await logAdminAction(
        'bulk_update_support_status',
        requestIds.join(','),
        'Bulk updated ${requestIds.length} support requests to status: $status',
        targetType: 'support'
      );
      
    } catch (e) {
      DebugHelper.logError('Error bulk updating support status: $e');
      setError('Failed to bulk update support status: $e');
      rethrow;
    }
  }

  Future<void> bulkDeleteSupportRequests(List<String> requestIds) async {
    try {
      final batch = firestore.batch();
      
      for (final requestId in requestIds) {
        final requestRef = firestore.collection('contact_submissions').doc(requestId);
        batch.delete(requestRef);
      }
      
      await batch.commit();
      
      // Remove from local data
      _supportRequests.removeWhere((request) => requestIds.contains(request['id']));
      
      // Update pending count
      _pendingSupportRequests = _supportRequests
          .where((request) => request['status'] == 'pending' || request['status'] == null)
          .length;
      
      updateLastUpdated();
      notifyListeners();
      
      // Log bulk action
      await logAdminAction(
        'bulk_delete_support',
        requestIds.join(','),
        'Bulk deleted ${requestIds.length} support requests',
        targetType: 'support'
      );
      
    } catch (e) {
      DebugHelper.logError('Error bulk deleting support requests: $e');
      setError('Failed to bulk delete support requests: $e');
      rethrow;
    }
  }

  // SEARCH AND FILTER

  List<Map<String, dynamic>> searchSupportRequests(String query) {
    if (query.isEmpty) return _supportRequests;
    
    final lowercaseQuery = query.toLowerCase();
    return _supportRequests.where((request) {
      final subject = (request['subject'] as String? ?? '').toLowerCase();
      final message = (request['message'] as String? ?? '').toLowerCase();
      final userEmail = (request['userEmail'] as String? ?? '').toLowerCase();
      final userName = (request['userName'] as String? ?? '').toLowerCase();
      final category = (request['category'] as String? ?? '').toLowerCase();
      
      return subject.contains(lowercaseQuery) ||
             message.contains(lowercaseQuery) ||
             userEmail.contains(lowercaseQuery) ||
             userName.contains(lowercaseQuery) ||
             category.contains(lowercaseQuery);
    }).toList();
  }

  List<Map<String, dynamic>> filterSupportRequests({
    String? status,
    String? priority,
    String? category,
    String? assignedTo,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _supportRequests.where((request) {
      // Status filter
      if (status != null && request['status'] != status) {
        return false;
      }
      
      // Priority filter
      if (priority != null && request['priority'] != priority) {
        return false;
      }
      
      // Category filter
      if (category != null && request['category'] != category) {
        return false;
      }
      
      // Assigned to filter
      if (assignedTo != null && request['assignedTo'] != assignedTo) {
        return false;
      }
      
      // Date filters
      final createdAt = request['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final date = createdAt.toDate();
        if (startDate != null && date.isBefore(startDate)) return false;
        if (endDate != null && date.isAfter(endDate)) return false;
      }
      
      return true;
    }).toList();
  }

  // ANALYTICS AND STATS

  List<Map<String, dynamic>> getPendingRequests() {
    return _supportRequests.where((request) => 
        request['status'] == 'pending' || request['status'] == null).toList();
  }

  List<Map<String, dynamic>> getHighPriorityRequests() {
    return _supportRequests.where((request) => request['priority'] == 'high').toList();
  }

  List<Map<String, dynamic>> getOverdueRequests() {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    
    return _supportRequests.where((request) {
      final createdAt = request['createdAt'] as Timestamp?;
      final status = request['status'];
      
      return createdAt != null && 
             createdAt.toDate().isBefore(threeDaysAgo) &&
             (status == 'pending' || status == null);
    }).toList();
  }

  Map<String, int> getRequestCountByCategory() {
    final categoryCount = <String, int>{};
    
    for (final request in _supportRequests) {
      final category = request['category'] as String? ?? 'General';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    return categoryCount;
  }

  Map<String, int> getRequestCountByStatus() {
    final statusCount = <String, int>{};
    
    for (final request in _supportRequests) {
      final status = request['status'] as String? ?? 'pending';
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }
    
    return statusCount;
  }

  Map<String, dynamic> getSupportStatistics() {
    final totalRequests = _supportRequests.length;
    final pendingRequests = getPendingRequests().length;
    final resolvedRequests = _supportRequests.where((r) => r['status'] == 'resolved').length;
    final highPriorityRequests = getHighPriorityRequests().length;
    final overdueRequests = getOverdueRequests().length;

    // Calculate average response time
    final resolvedWithResponse = _supportRequests.where((r) => 
        r['status'] == 'resolved' && r['responseDate'] != null && r['createdAt'] != null).toList();
    
    double averageResponseTime = 0;
    if (resolvedWithResponse.isNotEmpty) {
      int totalResponseTime = 0;
      for (final request in resolvedWithResponse) {
        final createdAt = (request['createdAt'] as Timestamp).toDate();
        final responseDate = (request['responseDate'] as Timestamp).toDate();
        totalResponseTime += responseDate.difference(createdAt).inHours;
      }
      averageResponseTime = totalResponseTime / resolvedWithResponse.length;
    }

    return {
      'totalRequests': totalRequests,
      'pendingRequests': pendingRequests,
      'resolvedRequests': resolvedRequests,
      'highPriorityRequests': highPriorityRequests,
      'overdueRequests': overdueRequests,
      'averageResponseTime': averageResponseTime,
      'resolutionRate': totalRequests > 0 ? (resolvedRequests / totalRequests) * 100 : 0,
      'categoryBreakdown': getRequestCountByCategory(),
      'statusBreakdown': getRequestCountByStatus(),
    };
  }

  // EXPORT

  Future<String> exportSupportData({
    List<String>? requestIds,
    String format = 'csv',
  }) async {
    try {
      final requestsToExport = requestIds != null 
          ? _supportRequests.where((request) => requestIds.contains(request['id'])).toList()
          : _supportRequests;
      
      if (format == 'csv') {
        final csv = StringBuffer();
        
        // CSV Headers
        csv.writeln('ID,Subject,Category,Status,Priority,User Email,User Name,Assigned To,Created At,Response Date');
        
        // CSV Data
        for (final request in requestsToExport) {
          csv.writeln([
            request['id'],
            request['subject'] ?? '',
            request['category'] ?? '',
            request['status'] ?? 'pending',
            request['priority'] ?? 'normal',
            request['userEmail'] ?? '',
            request['userName'] ?? '',
            request['assignedTo'] ?? '',
            formatDate(request['createdAt']),
            formatDate(request['responseDate']),
          ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
        }
        
        return csv.toString();
      }
      
      return '';
      
    } catch (e) {
      DebugHelper.logError('Error exporting support data: $e');
      rethrow;
    }
  }

  // UTILITY METHODS

  Map<String, dynamic>? getSupportRequestById(String requestId) {
    try {
      return _supportRequests.firstWhere(
        (request) => request['id'] == requestId,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      DebugHelper.logError('Error getting support request by ID: $e');
      return null;
    }
  }

  int getDaysSinceCreated(Map<String, dynamic> request) {
    final createdAt = request['createdAt'] as Timestamp?;
    if (createdAt == null) return 0;
    
    return DateTime.now().difference(createdAt.toDate()).inDays;
  }

  bool isOverdue(Map<String, dynamic> request) {
    final daysSince = getDaysSinceCreated(request);
    final status = request['status'];
    
    return daysSince > 3 && (status == 'pending' || status == null);
  }

  String getPriorityLabel(Map<String, dynamic> request) {
    final priority = request['priority'] as String? ?? 'normal';
    switch (priority) {
      case 'high':
        return '🔴 High';
      case 'medium':
        return '🟡 Medium';
      case 'low':
        return '🟢 Low';
      default:
        return '⚪ Normal';
    }
  }

  // DATA MANAGEMENT

  void clearAllSupportData() {
    _supportRequests.clear();
    _pendingSupportRequests = 0;
    notifyListeners();
  }

  // REFRESH DATA

  Future<void> refreshSupportRequests() async {
    await loadSupportRequests();
  }
}