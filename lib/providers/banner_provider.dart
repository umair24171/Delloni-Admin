// banner_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_admin_provider.dart';

class BannerProvider extends BaseAdminProvider {
  // Banner data
  List<Map<String, dynamic>> _allBanners = [];

  // Getters
  List<Map<String, dynamic>> get allBanners => _allBanners;

  // LOAD BANNER DATA

  Future<void> loadAllBanners() async {
    if (isLoading) return;
    
    setLoading(true);
    try {
      final bannersSnapshot = await firestore
          .collection('adBanners')
          .orderBy('createdAt', descending: true)
          .get();

      _allBanners = bannersSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      updateLastUpdated();
      notifyListeners();
      
      DebugHelper.logInfo('Loaded ${_allBanners.length} banners from Firestore');
    } catch (e) {
      DebugHelper.logError('Error loading banners: $e');
      setError('Failed to load banners: $e');
    }
    setLoading(false);
  }

  // BANNER MANAGEMENT OPERATIONS

  Future<void> createBanner(Map<String, dynamic> bannerData) async {
    setLoading(true);
    try {
      final docRef = await firestore.collection('adBanners').add({
        ...bannerData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Fetch the document to get the real timestamps
      final doc = await docRef.get();
      final data = doc.data();
      data?['id'] = doc.id;

      _allBanners.insert(0, data ?? {});
      updateLastUpdated();
      notifyListeners();

      // Log admin action
      await logAdminAction('create_banner', docRef.id, 'Banner created by admin: ${bannerData['title'] ?? 'Unknown'}', targetType: 'banner');
    } catch (e) {
      DebugHelper.logError('Error creating banner: $e');
      setError('Failed to create banner: $e');
      rethrow;
    }
    setLoading(false);
  }

  Future<void> updateBanner(String bannerId, Map<String, dynamic> bannerData) async {
    try {
      await firestore.collection('adBanners').doc(bannerId).update({
        ...bannerData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final bannerIndex = _allBanners.indexWhere((banner) => banner['id'] == bannerId);
      if (bannerIndex != -1) {
        _allBanners[bannerIndex] = {
          ..._allBanners[bannerIndex],
          ...bannerData,
          'id': bannerId,
          'updatedAt': Timestamp.now(),
        };
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction('update_banner', bannerId, 'Banner updated by admin', targetType: 'banner');
    } catch (e) {
      DebugHelper.logError('Error updating banner: $e');
      setError('Failed to update banner: $e');
      rethrow;
    }
  }

  Future<void> updateBannerStatus(String bannerId, bool isActive) async {
    try {
      await firestore.collection('adBanners').doc(bannerId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final bannerIndex = _allBanners.indexWhere((banner) => banner['id'] == bannerId);
      if (bannerIndex != -1) {
        _allBanners[bannerIndex]['isActive'] = isActive;
        _allBanners[bannerIndex]['updatedAt'] = Timestamp.now();
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction(
        isActive ? 'activate_banner' : 'deactivate_banner', 
        bannerId, 
        isActive ? 'Banner activated' : 'Banner deactivated',
        targetType: 'banner'
      );
    } catch (e) {
      DebugHelper.logError('Error updating banner status: $e');
      setError('Failed to update banner status: $e');
    }
  }

  Future<void> deleteBanner(String bannerId) async {
    try {
      // Get banner data for logging
      final bannerIndex = _allBanners.indexWhere((banner) => banner['id'] == bannerId);
      final bannerTitle = bannerIndex != -1 ? _allBanners[bannerIndex]['title'] ?? 'Unknown' : 'Unknown';

      await firestore.collection('adBanners').doc(bannerId).delete();
      
      if (bannerIndex != -1) {
        _allBanners.removeAt(bannerIndex);
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction('delete_banner', bannerId, 'Banner deleted by admin: $bannerTitle', targetType: 'banner');
    } catch (e) {
      DebugHelper.logError('Error deleting banner: $e');
      setError('Failed to delete banner: $e');
    }
  }

  // BULK OPERATIONS

  Future<void> bulkUpdateBannerStatus(List<String> bannerIds, bool isActive) async {
    try {
      final batch = firestore.batch();
      
      for (final bannerId in bannerIds) {
        final bannerRef = firestore.collection('adBanners').doc(bannerId);
        batch.update(bannerRef, {
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      // Update local data
      for (final bannerId in bannerIds) {
        final bannerIndex = _allBanners.indexWhere((banner) => banner['id'] == bannerId);
        if (bannerIndex != -1) {
          _allBanners[bannerIndex]['isActive'] = isActive;
          _allBanners[bannerIndex]['updatedAt'] = Timestamp.now();
        }
      }
      
      updateLastUpdated();
      notifyListeners();
      
      // Log bulk action
      await logAdminAction(
        'bulk_update_banner_status',
        bannerIds.join(','),
        'Bulk ${isActive ? 'activated' : 'deactivated'} ${bannerIds.length} banners',
        targetType: 'banner'
      );
      
    } catch (e) {
      DebugHelper.logError('Error bulk updating banner status: $e');
      setError('Failed to bulk update banner status: $e');
      rethrow;
    }
  }

  Future<void> bulkDeleteBanners(List<String> bannerIds) async {
    try {
      final batch = firestore.batch();
      
      for (final bannerId in bannerIds) {
        final bannerRef = firestore.collection('adBanners').doc(bannerId);
        batch.delete(bannerRef);
      }
      
      await batch.commit();
      
      // Remove from local data
      _allBanners.removeWhere((banner) => bannerIds.contains(banner['id']));
      updateLastUpdated();
      notifyListeners();
      
      // Log bulk action
      await logAdminAction(
        'bulk_delete_banners',
        bannerIds.join(','),
        'Bulk deleted ${bannerIds.length} banners',
        targetType: 'banner'
      );
      
    } catch (e) {
      DebugHelper.logError('Error bulk deleting banners: $e');
      setError('Failed to bulk delete banners: $e');
      rethrow;
    }
  }

  // BANNER ANALYTICS

  List<Map<String, dynamic>> getActiveBanners() {
    return _allBanners.where((banner) => banner['isActive'] == true).toList();
  }

  List<Map<String, dynamic>> getExpiredBanners() {
    final now = Timestamp.now();
    return _allBanners.where((banner) {
      final endDate = banner['endDate'] as Timestamp?;
      return endDate != null && endDate.compareTo(now) < 0;
    }).toList();
  }

  List<Map<String, dynamic>> getBannersByPosition(String position) {
    return _allBanners.where((banner) => banner['position'] == position).toList();
  }

  // SEARCH AND FILTER

  List<Map<String, dynamic>> searchBanners(String query) {
    if (query.isEmpty) return _allBanners;
    
    final lowercaseQuery = query.toLowerCase();
    return _allBanners.where((banner) {
      final title = (banner['title'] as String? ?? '').toLowerCase();
      final description = (banner['description'] as String? ?? '').toLowerCase();
      final position = (banner['position'] as String? ?? '').toLowerCase();
      
      return title.contains(lowercaseQuery) ||
             description.contains(lowercaseQuery) ||
             position.contains(lowercaseQuery);
    }).toList();
  }

  List<Map<String, dynamic>> filterBanners({
    bool? isActive,
    String? position,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _allBanners.where((banner) {
      // Active filter
      if (isActive != null && banner['isActive'] != isActive) {
        return false;
      }
      
      // Position filter
      if (position != null && banner['position'] != position) {
        return false;
      }
      
      // Date filters
      final createdAt = banner['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final date = createdAt.toDate();
        if (startDate != null && date.isBefore(startDate)) return false;
        if (endDate != null && date.isAfter(endDate)) return false;
      }
      
      return true;
    }).toList();
  }

  // STATISTICS

  Map<String, dynamic> getBannerStatistics() {
    final activeBanners = _allBanners.where((banner) => banner['isActive'] == true).length;
    final inactiveBanners = _allBanners.where((banner) => banner['isActive'] == false).length;
    final expiredBanners = getExpiredBanners().length;

    // Count by position
    final positionCounts = <String, int>{};
    for (final banner in _allBanners) {
      final position = banner['position'] as String? ?? 'unknown';
      positionCounts[position] = (positionCounts[position] ?? 0) + 1;
    }

    return {
      'totalBanners': _allBanners.length,
      'activeBanners': activeBanners,
      'inactiveBanners': inactiveBanners,
      'expiredBanners': expiredBanners,
      'positionCounts': positionCounts,
    };
  }

  // EXPORT

  Future<String> exportBannersData({
    List<String>? bannerIds,
    String format = 'csv',
  }) async {
    try {
      final bannersToExport = bannerIds != null 
          ? _allBanners.where((banner) => bannerIds.contains(banner['id'])).toList()
          : _allBanners;
      
      if (format == 'csv') {
        final csv = StringBuffer();
        
        // CSV Headers
        csv.writeln('ID,Title,Description,Position,Status,Start Date,End Date,Created At');
        
        // CSV Data
        for (final banner in bannersToExport) {
          csv.writeln([
            banner['id'],
            banner['title'] ?? '',
            banner['description'] ?? '',
            banner['position'] ?? '',
            banner['isActive'] == true ? 'Active' : 'Inactive',
            formatDate(banner['startDate']),
            formatDate(banner['endDate']),
            formatDate(banner['createdAt']),
          ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
        }
        
        return csv.toString();
      }
      
      return '';
      
    } catch (e) {
      DebugHelper.logError('Error exporting banners data: $e');
      rethrow;
    }
  }

  // VALIDATION

  Future<bool> validateBannerData(Map<String, dynamic> bannerData) async {
    try {
      // Check required fields
      final requiredFields = ['title', 'imageUrl', 'position'];
      
      for (final field in requiredFields) {
        if (!bannerData.containsKey(field) || bannerData[field] == null || bannerData[field].toString().isEmpty) {
          setError('Missing required field: $field');
          return false;
        }
      }
      
      // Validate position
      final validPositions = ['header', 'footer', 'sidebar', 'content', 'popup'];
      final position = bannerData['position'] as String?;
      if (position != null && !validPositions.contains(position)) {
        setError('Invalid position. Must be one of: ${validPositions.join(', ')}');
        return false;
      }
      
      // Validate dates if provided
      final startDate = bannerData['startDate'];
      final endDate = bannerData['endDate'];
      
      if (startDate != null && endDate != null) {
        DateTime? start;
        DateTime? end;
        
        if (startDate is Timestamp) start = startDate.toDate();
        if (endDate is Timestamp) end = endDate.toDate();
        
        if (start != null && end != null && start.isAfter(end)) {
          setError('Start date must be before end date');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      DebugHelper.logError('Error validating banner data: $e');
      setError('Validation error: $e');
      return false;
    }
  }

  // DATA MANAGEMENT

  void clearAllBannerData() {
    _allBanners.clear();
    notifyListeners();
  }

  // UTILITY METHODS

  Map<String, dynamic>? getBannerById(String bannerId) {
    try {
      return _allBanners.firstWhere(
        (banner) => banner['id'] == bannerId,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      DebugHelper.logError('Error getting banner by ID: $e');
      return null;
    }
  }

  bool isBannerExpired(Map<String, dynamic> banner) {
    final endDate = banner['endDate'] as Timestamp?;
    if (endDate == null) return false;
    
    return endDate.toDate().isBefore(DateTime.now());
  }

  int getDaysUntilExpiry(Map<String, dynamic> banner) {
    final endDate = banner['endDate'] as Timestamp?;
    if (endDate == null) return -1;
    
    final now = DateTime.now();
    final expiry = endDate.toDate();
    
    if (expiry.isBefore(now)) return 0;
    
    return expiry.difference(now).inDays;
  }
}