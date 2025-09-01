// base_admin_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class BaseAdminProvider with ChangeNotifier {
  // Shared Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Shared state
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  // Shared methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void updateLastUpdated() {
    _lastUpdated = DateTime.now();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to format date for export
  String formatDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is Timestamp) {
        return date.toDate().toIso8601String();
      } else if (date is DateTime) {
        return date.toIso8601String();
      } else if (date is String) {
        return DateTime.parse(date).toIso8601String();
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  // Admin action logging
  Future<void> logAdminAction(String action, String targetId, String description, {String targetType = 'general'}) async {
    try {
      await _firestore.collection('admin_logs').add({
        'action': action,
        'targetId': targetId,
        'targetType': targetType,
        'description': description,
        'adminId': 'current_admin', // Replace with actual admin ID
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': '', // Add IP tracking if needed
      });
    } catch (e) {
      DebugHelper.logError('Error logging admin action: $e');
      // Don't throw error here as it's just logging
    }
  }

  // Image upload helper
  Future<String> uploadImage(Uint8List imageData, String fileName) async {
    try {
      final ref = _storage.ref().child('admin_uploads/$fileName');
      final uploadTask = ref.putData(imageData);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      DebugHelper.logError('Failed to upload image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }
}

// Debug helper class
class DebugHelper {
  static void logInfo(String message) {
    if (kDebugMode) {
      print('ℹ️ $message');
    }
  }

  static void logError(String message) {
    if (kDebugMode) {
      print('❌ $message');
    }
  }
}