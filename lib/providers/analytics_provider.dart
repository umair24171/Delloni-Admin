// analytics_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'base_admin_provider.dart';

class AnalyticsProvider extends BaseAdminProvider {
  // Analytics loading state
  bool _isAnalyticsLoading = false;

  // Analytics collections
  List<Map<String, dynamic>> _topSearches = [];
  List<Map<String, dynamic>> _categoryTrends = [];
  List<Map<String, dynamic>> _locationData = [];
  List<Map<String, dynamic>> _topCities = [];
  List<Map<String, dynamic>> _topUsers = [];
  List<Map<String, dynamic>> _recentActivity = [];

  // Revenue and orders
  int _totalOrders = 0;
  int _totalRevenue = 0;
  int _monthlyRevenue = 0;
  double _revenueGrowthPercentage = 0.0;
  String _revenueTrend = 'up';

  // Caching system
  final Map<String, dynamic> _analyticsCache = {};
  static const Duration _cacheTimeout = Duration(minutes: 10);
  DateTime? _lastCacheUpdate;

  // Getters
  bool get isAnalyticsLoading => _isAnalyticsLoading;
  List<Map<String, dynamic>> get topSearches => _topSearches;
  List<Map<String, dynamic>> get categoryTrends => _categoryTrends;
  List<Map<String, dynamic>> get locationData => _locationData;
  List<Map<String, dynamic>> get topCities => _topCities;
  List<Map<String, dynamic>> get topUsers => _topUsers;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  int get totalOrders => _totalOrders;
  int get totalRevenue => _totalRevenue;
  int get monthlyRevenue => _monthlyRevenue;
  double get revenueGrowthPercentage => _revenueGrowthPercentage;
  String get revenueTrend => _revenueTrend;

  // ANALYTICS LOADING

  void setAnalyticsLoading(bool loading) {
    _isAnalyticsLoading = loading;
    notifyListeners();
  }

  Future<void> loadAnalyticsData() async {
    if (_isAnalyticsLoading) return;
    
    setAnalyticsLoading(true);

    try {
      // Check cache first
      if (_shouldUseCache()) {
        _loadFromCache();
        setAnalyticsLoading(false);
        return;
      }

      // Load analytics in parallel
      await Future.wait([
        _loadGrowthMetrics(),
        _loadTopSearches(),
        _loadCategoryTrends(),
        _loadLocationAnalytics(),
        _loadTopUsers(),
        _loadRecentActivity(),
        _loadRevenueData(),
      ]);

      _updateAnalyticsCache();
      updateLastUpdated();
    } catch (e) {
      DebugHelper.logError('Failed to load analytics data: $e');
      setError('Failed to load analytics data: $e');
    }

    setAnalyticsLoading(false);
  }

  Future<void> _loadGrowthMetrics() async {
    // Growth metrics are calculated in individual load methods
    // This method can be used for additional complex calculations
    DebugHelper.logInfo('Loading growth metrics...');
  }

  Future<void> _loadTopSearches() async {
    try {
      // In a real app, you'd have a searches collection
      // For now, creating realistic mock data based on actual products
      final productsSnapshot = await firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .limit(100)
          .get();

      // Simulate search trends based on popular categories/brands
      final searchTerms = <String, int>{};
      
      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        final brand = data['brand'] as String?;
        final category = data['categoryName'] as String?;
        final title = data['itemTitle'] as String?;
        
        if (brand != null && brand.isNotEmpty) {
          searchTerms[brand] = (searchTerms[brand] ?? 0) + Random().nextInt(50) + 10;
        }
        if (category != null && category.isNotEmpty) {
          searchTerms[category] = (searchTerms[category] ?? 0) + Random().nextInt(30) + 5;
        }
        if (title != null && title.isNotEmpty) {
          final words = title.split(' ');
          for (final word in words.take(2)) {
            if (word.length > 3) {
              searchTerms[word] = (searchTerms[word] ?? 0) + Random().nextInt(20) + 1;
            }
          }
        }
      }

      _topSearches = searchTerms.entries
          .map((entry) => {
                'term': entry.key,
                'count': entry.value,
              })
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int))
        ..take(8).toList();

      DebugHelper.logInfo('Loaded ${_topSearches.length} top searches');
    } catch (e) {
      DebugHelper.logError('Error loading top searches: $e');
      // Fallback to mock data
      _topSearches = [
        {'term': 'iPhone 14 Pro', 'count': 1250},
        {'term': 'Samsung Galaxy', 'count': 980},
        {'term': 'MacBook Pro', 'count': 765},
        {'term': 'Car Toyota', 'count': 654},
        {'term': 'House for sale', 'count': 543},
        {'term': 'Laptop Dell', 'count': 432},
        {'term': 'Mobile Huawei', 'count': 321},
        {'term': 'Bike Honda', 'count': 298},
      ];
    }
  }

  Future<void> _loadCategoryTrends() async {
    try {
      // Get products grouped by category
      final productsSnapshot = await firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .get();

      final categoryCount = <String, int>{};
      final total = productsSnapshot.docs.length;

      for (final doc in productsSnapshot.docs) {
        final categoryName = doc.data()['categoryName'] as String? ?? 'Unknown';
        categoryCount[categoryName] = (categoryCount[categoryName] ?? 0) + 1;
      }

      _categoryTrends = categoryCount.entries
          .map((entry) => {
                'name': entry.key,
                'count': entry.value,
                'percentage': total > 0 ? (entry.value / total) * 100 : 0.0,
                'trend': Random().nextBool() ? 'up' : 'down',
                'growth': Random().nextDouble() * 20 - 10, // -10 to +10
              })
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      DebugHelper.logInfo('Loaded category trends for ${_categoryTrends.length} categories');
    } catch (e) {
      DebugHelper.logError('Error loading category trends: $e');
    }
  }

  Future<void> _loadLocationAnalytics() async {
    try {
      // Get products with location data
      final productsSnapshot = await firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .get();

      final cityCount = <String, Map<String, dynamic>>{};

      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        final cityName = data['cityName'] as String? ?? 'Unknown';
        final stateName = data['stateName'] as String? ?? '';
        
        if (!cityCount.containsKey(cityName)) {
          cityCount[cityName] = {
            'name': cityName,
            'state': stateName,
            'userCount': 0,
            'listingCount': 0,
            'isGrowing': Random().nextBool(),
            'growthRate': Random().nextDouble() * 30 - 15, // -15 to +15
          };
        }
        
        cityCount[cityName]!['listingCount'] = 
            (cityCount[cityName]!['listingCount'] as int) + 1;
      }

      // Get user counts by city
      final usersSnapshot = await firestore.collection('users').get();
      for (final doc in usersSnapshot.docs) {
        final cityName = doc.data()['cityName'] as String? ?? 'Unknown';
        if (cityCount.containsKey(cityName)) {
          cityCount[cityName]!['userCount'] = 
              (cityCount[cityName]!['userCount'] as int) + 1;
        }
      }

      _topCities = cityCount.values.toList()
        ..sort((a, b) => 
            (b['listingCount'] as int).compareTo(a['listingCount'] as int))
        ..take(10).toList();

      // Generate heatmap data (simplified)
      _locationData = List.generate(25, (index) => {
        'intensity': Random().nextDouble(),
        'region': 'Region ${index + 1}',
        'count': Random().nextInt(1000) + 50,
        'growth': Random().nextDouble() * 40 - 20, // -20 to +20
      });

      DebugHelper.logInfo('Loaded location analytics for ${_topCities.length} cities');
    } catch (e) {
      DebugHelper.logError('Error loading location analytics: $e');
    }
  }

  Future<void> _loadTopUsers() async {
    try {
      // Get users with their listing counts
      final usersSnapshot = await firestore.collection('users').get();
      final userListingCounts = <String, Map<String, dynamic>>{};

      // Initialize user data
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        userListingCounts[doc.id] = {
          'id': doc.id,
          'companyName': data['companyName'] ?? data['name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'type': data['type'] ?? 'individual',
          'listingCount': 0,
          'totalViews': Random().nextInt(10000) + 100,
          'totalSales': Random().nextInt(50) + 1,
          'joinedAt': data['createdAt'],
          'isActive': data['isActive'] ?? true,
        };
      }

      // Count listings per user
      final productsSnapshot = await firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in productsSnapshot.docs) {
        final sellerId = doc.data()['sellerId'] as String?;
        if (sellerId != null && userListingCounts.containsKey(sellerId)) {
          userListingCounts[sellerId]!['listingCount'] = 
              (userListingCounts[sellerId]!['listingCount'] as int) + 1;
        }
      }

      _topUsers = userListingCounts.values
          .where((user) => (user['listingCount'] as int) > 0)
          .toList()
        ..sort((a, b) => 
            (b['listingCount'] as int).compareTo(a['listingCount'] as int))
        ..take(10).toList();

      DebugHelper.logInfo('Loaded ${_topUsers.length} top users');
    } catch (e) {
      DebugHelper.logError('Error loading top users: $e');
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      final activities = <Map<String, dynamic>>[];

      // Get recent user registrations
      final recentUsersSnapshot = await firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final doc in recentUsersSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'user_registered',
          'icon': '👤',
          'message': '${data['companyName'] ?? data['email'] ?? 'New user'} registered',
          'timestamp': data['createdAt'],
          'severity': 'info',
        });
      }

      // Get recent product additions
      final recentProductsSnapshot = await firestore
          .collection('items')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final doc in recentProductsSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'product_added',
          'icon': '📦',
          'message': 'New product "${data['itemTitle'] ?? 'Unknown'}" added',
          'timestamp': data['createdAt'],
          'severity': 'success',
        });
      }

      // Get recent support requests
      final recentSupportSnapshot = await firestore
          .collection('contact_submissions')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      for (final doc in recentSupportSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'support_request',
          'icon': '🎧',
          'message': 'New support request: ${data['subject'] ?? 'General inquiry'}',
          'timestamp': data['createdAt'],
          'severity': 'warning',
        });
      }

      // Get recent reports
      final recentReportsSnapshot = await firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .limit(2)
          .get();

      for (final doc in recentReportsSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'report_submitted',
          'icon': '⚠️',
          'message': 'New report: ${data['reportReason'] ?? 'Unknown reason'}',
          'timestamp': data['createdAt'],
          'severity': 'error',
        });
      }

      // Sort all activities by timestamp
      activities.sort((a, b) {
        final timestampA = a['timestamp'] as Timestamp?;
        final timestampB = b['timestamp'] as Timestamp?;
        
        if (timestampA == null) return 1;
        if (timestampB == null) return -1;
        
        return timestampB.compareTo(timestampA);
      });

      _recentActivity = activities.take(10).toList();

      DebugHelper.logInfo('Loaded ${_recentActivity.length} recent activities');
    } catch (e) {
      DebugHelper.logError('Error loading recent activity: $e');
    }
  }

  Future<void> _loadRevenueData() async {
    try {
      // Calculate revenue from premium features, featured listings, etc.
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      // Example: Featured listings revenue
      final featuredListingsSnapshot = await firestore
          .collection('payments')
          .where('type', isEqualTo: 'featured_listing')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get();
      
      _monthlyRevenue = featuredListingsSnapshot.docs.fold<int>(0, (sum, doc) {
        final amount = doc.data()['amount'] as int? ?? 0;
        return sum + amount;
      });

      // Mock total revenue calculation
      _totalRevenue = _monthlyRevenue * 12; // Simplified

      // Mock orders for now
      _totalOrders = 156 + Random().nextInt(50);

      // Calculate revenue growth
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      final previousMonthEnd = DateTime(now.year, now.month, 0);
      
      final previousMonthSnapshot = await firestore
          .collection('payments')
          .where('type', isEqualTo: 'featured_listing')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(previousMonth))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(previousMonthEnd))
          .get();
      
      final previousMonthRevenue = previousMonthSnapshot.docs.fold<int>(0, (sum, doc) {
        final amount = doc.data()['amount'] as int? ?? 0;
        return sum + amount;
      });

      if (previousMonthRevenue > 0) {
        _revenueGrowthPercentage = ((_monthlyRevenue - previousMonthRevenue) / previousMonthRevenue) * 100;
        _revenueTrend = _revenueGrowthPercentage > 0 ? 'up' : 'down';
      }

      DebugHelper.logInfo('Loaded revenue data: Monthly: $_monthlyRevenue, Total: $_totalRevenue');
    } catch (e) {
      DebugHelper.logError('Error loading revenue data: $e');
      // Fallback to mock data
      _totalOrders = 156;
      _totalRevenue = 45600;
      _monthlyRevenue = 8500;
      _revenueGrowthPercentage = 12.5;
      _revenueTrend = 'up';
    }
  }

  // ADVANCED ANALYTICS

  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));
      
      // Get daily stats
      final todayUsers = await firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, now.day)))
          .get();
      
      final todayProducts = await firestore
          .collection('items')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, now.day)))
          .get();

      // Get weekly growth
      final weeklyUsers = await firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();
      
      final weeklyProducts = await firestore
          .collection('items')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      return {
        'todayNewUsers': todayUsers.docs.length,
        'todayNewProducts': todayProducts.docs.length,
        'weeklyNewUsers': weeklyUsers.docs.length,
        'weeklyNewProducts': weeklyProducts.docs.length,
        'totalRevenue': _totalRevenue,
        'monthlyRevenue': _monthlyRevenue,
        'revenueGrowth': _revenueGrowthPercentage,
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      DebugHelper.logError('Error getting dashboard summary: $e');
      return {};
    }
  }

  Map<String, List<Map<String, dynamic>>> getAnalyticsByTimeframe(String timeframe) {
    // This would implement time-based analytics
    // For now, return current data grouped by timeframe
    return {
      'topSearches': _topSearches,
      'categoryTrends': _categoryTrends,
      'topUsers': _topUsers,
      'recentActivity': _recentActivity.take(timeframe == 'today' ? 5 : 10).toList(),
    };
  }

  Future<Map<String, dynamic>> getGrowthMetrics() async {
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, now.day);
      final twoMonthsAgo = DateTime(now.year, now.month - 2, now.day);

      // Get current month data
      final currentUsers = await firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(lastMonth))
          .get();

      final currentProducts = await firestore
          .collection('items')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(lastMonth))
          .get();

      // Get previous month data
      final previousUsers = await firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(twoMonthsAgo))
          .where('createdAt', isLessThan: Timestamp.fromDate(lastMonth))
          .get();

      final previousProducts = await firestore
          .collection('items')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(twoMonthsAgo))
          .where('createdAt', isLessThan: Timestamp.fromDate(lastMonth))
          .get();

      // Calculate growth percentages
      final userGrowth = previousUsers.docs.isEmpty ? 0.0 : 
          ((currentUsers.docs.length - previousUsers.docs.length) / previousUsers.docs.length) * 100;
      
      final productGrowth = previousProducts.docs.isEmpty ? 0.0 : 
          ((currentProducts.docs.length - previousProducts.docs.length) / previousProducts.docs.length) * 100;

      return {
        'userGrowth': userGrowth,
        'productGrowth': productGrowth,
        'revenueGrowth': _revenueGrowthPercentage,
        'currentUsers': currentUsers.docs.length,
        'currentProducts': currentProducts.docs.length,
        'previousUsers': previousUsers.docs.length,
        'previousProducts': previousProducts.docs.length,
      };
    } catch (e) {
      DebugHelper.logError('Error getting growth metrics: $e');
      return {};
    }
  }

  // CACHING SYSTEM

  bool _shouldUseCache() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }

  void _updateAnalyticsCache() {
    _analyticsCache.clear();
    _analyticsCache.addAll({
      'topSearches': _topSearches,
      'categoryTrends': _categoryTrends,
      'locationData': _locationData,
      'topCities': _topCities,
      'topUsers': _topUsers,
      'recentActivity': _recentActivity,
      'totalOrders': _totalOrders,
      'totalRevenue': _totalRevenue,
      'monthlyRevenue': _monthlyRevenue,
      'revenueGrowthPercentage': _revenueGrowthPercentage,
      'revenueTrend': _revenueTrend,
    });
    _lastCacheUpdate = DateTime.now();
  }

  void _loadFromCache() {
    _topSearches = List<Map<String, dynamic>>.from(
        _analyticsCache['topSearches'] ?? []);
    _categoryTrends = List<Map<String, dynamic>>.from(
        _analyticsCache['categoryTrends'] ?? []);
    _locationData = List<Map<String, dynamic>>.from(
        _analyticsCache['locationData'] ?? []);
    _topCities = List<Map<String, dynamic>>.from(
        _analyticsCache['topCities'] ?? []);
    _topUsers = List<Map<String, dynamic>>.from(
        _analyticsCache['topUsers'] ?? []);
    _recentActivity = List<Map<String, dynamic>>.from(
        _analyticsCache['recentActivity'] ?? []);
    _totalOrders = _analyticsCache['totalOrders'] ?? 0;
    _totalRevenue = _analyticsCache['totalRevenue'] ?? 0;
    _monthlyRevenue = _analyticsCache['monthlyRevenue'] ?? 0;
    _revenueGrowthPercentage = _analyticsCache['revenueGrowthPercentage'] ?? 0.0;
    _revenueTrend = _analyticsCache['revenueTrend'] ?? 'up';
  }

  void clearCache() {
    _analyticsCache.clear();
    _lastCacheUpdate = null;
  }

  // REFRESH ANALYTICS

  Future<void> refreshAnalytics() async {
    clearCache();
    await loadAnalyticsData();
  }

  // EXPORT ANALYTICS

  Future<String> exportAnalyticsData(String dataType, {String format = 'csv'}) async {
    try {
      List<Map<String, dynamic>> dataToExport = [];
      String fileName = '';

      switch (dataType) {
        case 'topSearches':
          dataToExport = _topSearches;
          fileName = 'top_searches';
          break;
        case 'categoryTrends':
          dataToExport = _categoryTrends;
          fileName = 'category_trends';
          break;
        case 'topUsers':
          dataToExport = _topUsers;
          fileName = 'top_users';
          break;
        case 'topCities':
          dataToExport = _topCities;
          fileName = 'top_cities';
          break;
        default:
          throw Exception('Unknown data type: $dataType');
      }

      if (format == 'csv') {
        final csv = StringBuffer();
        
        if (dataToExport.isNotEmpty) {
          // CSV Headers
          final headers = dataToExport.first.keys.toList();
          csv.writeln(headers.join(','));
          
          // CSV Data
          for (final item in dataToExport) {
            final values = headers.map((key) => 
                '"${item[key].toString().replaceAll('"', '""')}"').join(',');
            csv.writeln(values);
          }
        }
        
        return csv.toString();
      }
      
      return '';
      
    } catch (e) {
      DebugHelper.logError('Error exporting analytics data: $e');
      rethrow;
    }
  }

  // DATA MANAGEMENT

  void clearAllAnalyticsData() {
    _topSearches.clear();
    _categoryTrends.clear();
    _locationData.clear();
    _topCities.clear();
    _topUsers.clear();
    _recentActivity.clear();
    _totalOrders = 0;
    _totalRevenue = 0;
    _monthlyRevenue = 0;
    _revenueGrowthPercentage = 0.0;
    _revenueTrend = 'up';
    clearCache();
    notifyListeners();
  }
}