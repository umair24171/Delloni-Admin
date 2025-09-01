// dashboard_data_provider.dart
import 'package:flutter/foundation.dart';
import 'base_admin_provider.dart';
import 'category_provider.dart' hide DebugHelper;
import 'user_provider.dart';
import 'product_provider.dart';
import 'reports_provider.dart';
import 'banner_provider.dart';
import 'support_provider.dart';
import 'chat_provider.dart';
import 'analytics_provider.dart';

class DashboardDataProvider extends BaseAdminProvider {
  // Individual providers
  late final CategoryProvider _categoryProvider;
  late final UserProvider _userProvider;
  late final ProductProvider _productProvider;
  late final ReportsProvider _reportsProvider;
  late final BannerProvider _bannerProvider;
  late final SupportProvider _supportProvider;
  late final ChatProvider _chatProvider;
  late final AnalyticsProvider _analyticsProvider;

  // Dashboard loading states
  bool _isDashboardLoading = false;

  // Getters for providers
  CategoryProvider get categoryProvider => _categoryProvider;
  UserProvider get userProvider => _userProvider;
  ProductProvider get productProvider => _productProvider;
  ReportsProvider get reportsProvider => _reportsProvider;
  BannerProvider get bannerProvider => _bannerProvider;
  SupportProvider get supportProvider => _supportProvider;
  ChatProvider get chatProvider => _chatProvider;
  AnalyticsProvider get analyticsProvider => _analyticsProvider;

  // Dashboard loading state
  bool get isDashboardLoading => _isDashboardLoading;

  // Constructor
  DashboardDataProvider() {
    _initializeProviders();
  }

  void _initializeProviders() {
    _categoryProvider = CategoryProvider();
    _userProvider = UserProvider();
    _productProvider = ProductProvider();
    _reportsProvider = ReportsProvider();
    _bannerProvider = BannerProvider();
    _supportProvider = SupportProvider();
    _chatProvider = ChatProvider();
    _analyticsProvider = AnalyticsProvider();

    // Listen to individual provider changes
    _categoryProvider.addListener(_onProviderChanged);
    _userProvider.addListener(_onProviderChanged);
    _productProvider.addListener(_onProviderChanged);
    _reportsProvider.addListener(_onProviderChanged);
    _bannerProvider.addListener(_onProviderChanged);
    _supportProvider.addListener(_onProviderChanged);
    _chatProvider.addListener(_onProviderChanged);
    _analyticsProvider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    // Propagate changes from individual providers
    notifyListeners();
  }

  // MAIN INITIALIZATION

  Future<void> initializeAdminData() async {
    DebugHelper.logInfo('Initializing admin data...');
    
    try {
      setError(null);
      
      // Load all data in parallel for better performance
      await Future.wait([
        _categoryProvider.loadAllCategories(),
        _userProvider.loadAllUsers(),
        _productProvider.loadAllProducts(),
        _bannerProvider.loadAllBanners(),
        _supportProvider.loadSupportRequests(),
        _reportsProvider.loadAllReports(),
        _categoryProvider.loadAllTemplates(),
      ]);
      
      DebugHelper.logInfo('Admin data initialization completed');
    } catch (e) {
      DebugHelper.logError('Failed to initialize admin data: $e');
      setError('Failed to initialize admin data: $e');
    }
  }

  // DASHBOARD DATA LOADING

  void setDashboardLoading(bool loading) {
    _isDashboardLoading = loading;
    notifyListeners();
  }

  Future<void> loadDashboardData() async {
    if (_isDashboardLoading) return; // Prevent multiple simultaneous loads
    
    setDashboardLoading(true);
    setError(null);

    try {
      // Load basic stats in parallel
      await Future.wait([
        _userProvider.loadUserStats(),
        _productProvider.loadProductStats(),
        _chatProvider.loadChatStats(),
        _supportProvider.loadSupportStats(),
      ]);

      updateLastUpdated();
    } catch (e) {
      DebugHelper.logError('Failed to load dashboard data: $e');
      setError('Failed to load dashboard data: $e');
    }

    setDashboardLoading(false);
  }

  Future<void> refreshDashboardData() async {
    _analyticsProvider.clearCache();
    await Future.wait([
      loadDashboardData(),
      _analyticsProvider.loadAnalyticsData(),
    ]);
  }

  // AGGREGATE GETTERS (combining data from multiple providers)

  // Basic Stats
  int get totalUsers => _userProvider.totalUsers;
  int get totalProducts => _productProvider.totalProducts;
  int get totalOrders => _analyticsProvider.totalOrders;
  int get totalRevenue => _analyticsProvider.totalRevenue;
  int get activeChats => _chatProvider.activeChats;
  int get pendingSupportRequests => _supportProvider.pendingSupportRequests;

  // Enhanced Analytics
  int get todayNewUsers => _userProvider.todayNewUsers;
  int get todayNewProducts => _productProvider.todayNewProducts;
  int get newUsersThisWeek => _userProvider.newUsersThisWeek;
  int get newListingsThisWeek => _productProvider.newListingsThisWeek;
  int get monthlyRevenue => _analyticsProvider.monthlyRevenue;
  int get averageResponseTime => _chatProvider.averageResponseTime;

  // Growth metrics
  double get userGrowthPercentage => _userProvider.userGrowthPercentage;
  double get listingGrowthPercentage => _productProvider.listingGrowthPercentage;
  double get revenueGrowthPercentage => _analyticsProvider.revenueGrowthPercentage;
  double get chatGrowthPercentage => _chatProvider.chatGrowthPercentage;
  String get userTrend => _userProvider.userTrend;
  String get listingTrend => _productProvider.listingTrend;
  String get revenueTrend => _analyticsProvider.revenueTrend;
  String get chatTrend => _chatProvider.chatTrend;

  // Analytics collections
  List<Map<String, dynamic>> get topSearches => _analyticsProvider.topSearches;
  List<Map<String, dynamic>> get categoryTrends => _analyticsProvider.categoryTrends;
  List<Map<String, dynamic>> get locationData => _analyticsProvider.locationData;
  List<Map<String, dynamic>> get topCities => _analyticsProvider.topCities;
  List<Map<String, dynamic>> get topUsers => _analyticsProvider.topUsers;
  List<Map<String, dynamic>> get recentActivity => _analyticsProvider.recentActivity;

  // Core data
  List<Map<String, dynamic>> get recentUsers => _userProvider.recentUsers;
  List<Map<String, dynamic>> get recentProducts => _productProvider.recentProducts;
  List<Map<String, dynamic>> get supportRequests => _supportProvider.supportRequests;
  List<Map<String, dynamic>> get allUsers => _userProvider.allUsers;
  List<Map<String, dynamic>> get allProducts => _productProvider.allProducts;
  List<Map<String, dynamic>> get allBanners => _bannerProvider.allBanners;
  List<Map<String, dynamic>> get chatConversations => _chatProvider.chatConversations;
  List<Map<String, dynamic>> get allCategories => _categoryProvider.allCategories;
  List<Map<String, dynamic>> get allTemplates => _categoryProvider.allTemplates;

  // Reports
  List<Map<String, dynamic>> get allChatReports => _reportsProvider.allChatReports;
  List<Map<String, dynamic>> get allAccountReports => _reportsProvider.allAccountReports;
  List<Map<String, dynamic>> get allReports => _reportsProvider.allReports;

  // COMPREHENSIVE STATISTICS

  Map<String, dynamic> getDashboardSummary() {
    return {
      // Basic counts
      'totalUsers': totalUsers,
      'totalProducts': totalProducts,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'activeChats': activeChats,
      'pendingSupportRequests': pendingSupportRequests,
      
      // Growth metrics
      'userGrowthPercentage': userGrowthPercentage,
      'listingGrowthPercentage': listingGrowthPercentage,
      'revenueGrowthPercentage': revenueGrowthPercentage,
      'chatGrowthPercentage': chatGrowthPercentage,
      
      // Trends
      'userTrend': userTrend,
      'listingTrend': listingTrend,
      'revenueTrend': revenueTrend,
      'chatTrend': chatTrend,
      
      // Recent activity
      'todayNewUsers': todayNewUsers,
      'todayNewProducts': todayNewProducts,
      'newUsersThisWeek': newUsersThisWeek,
      'newListingsThisWeek': newListingsThisWeek,
      
      // System health
      'averageResponseTime': averageResponseTime,
      'lastUpdated': lastUpdated,
    };
  }

  Map<String, dynamic> getCombinedStatistics() {
    return {
      'users': _userProvider.getUserStatistics(),
      'products': _productProvider.getProductStatistics(),
      'categories': _categoryProvider.getCategoryStatistics(),
      'support': _supportProvider.getSupportStatistics(),
      'reports': _reportsProvider.getReportStatistics(),
      'chats': _chatProvider.getChatStatistics(),
      'banners': _bannerProvider.getBannerStatistics(),
    };
  }

  // SEARCH ACROSS ALL PROVIDERS

  Map<String, List<Map<String, dynamic>>> searchAll(String query) {
    if (query.isEmpty) {
      return {
        'users': [],
        'products': [],
        'categories': [],
        'reports': [],
        'support': [],
        'banners': [],
        'chats': [],
      };
    }

    return {
      'users': _userProvider.searchUsers(query),
      'products': _productProvider.searchProducts(query),
      'categories': _categoryProvider.searchCategories(query),
      'reports': _reportsProvider.searchReports(query),
      'support': _supportProvider.searchSupportRequests(query),
      'banners': _bannerProvider.searchBanners(query),
      'chats': _chatProvider.searchChats(query),
    };
  }

  // BULK OPERATIONS ACROSS PROVIDERS

  Future<void> performBulkAction(String action, String dataType, List<String> ids, {Map<String, dynamic>? params}) async {
    try {
      switch (dataType) {
        case 'users':
          switch (action) {
            case 'updateStatus':
              await _userProvider.bulkUpdateUserStatus(ids, params?['isActive'] ?? true);
              break;
          }
          break;
        
        case 'products':
          switch (action) {
            case 'updateStatus':
              await _productProvider.bulkUpdateProductStatus(ids, params?['status'] ?? 'active');
              break;
            case 'delete':
              await _productProvider.bulkDeleteProducts(ids);
              break;
          }
          break;
        
        case 'reports':
          switch (action) {
            case 'updateStatus':
              final reports = allReports.where((r) => ids.contains(r['id'])).toList();
              await _reportsProvider.bulkUpdateReportStatus(reports, params?['status'] ?? 'resolved');
              break;
            case 'delete':
              final reports = allReports.where((r) => ids.contains(r['id'])).toList();
              await _reportsProvider.bulkDeleteReports(reports);
              break;
          }
          break;
        
        case 'support':
          switch (action) {
            case 'updateStatus':
              await _supportProvider.bulkUpdateSupportStatus(ids, params?['status'] ?? 'resolved');
              break;
            case 'delete':
              await _supportProvider.bulkDeleteSupportRequests(ids);
              break;
          }
          break;
        
        case 'banners':
          switch (action) {
            case 'updateStatus':
              await _bannerProvider.bulkUpdateBannerStatus(ids, params?['isActive'] ?? true);
              break;
            case 'delete':
              await _bannerProvider.bulkDeleteBanners(ids);
              break;
          }
          break;
        
        case 'chats':
          switch (action) {
            case 'updateStatus':
              await _chatProvider.bulkUpdateChatStatus(ids, params?['isActive'] ?? true);
              break;
            case 'delete':
              await _chatProvider.bulkDeleteChats(ids);
              break;
          }
          break;
      }
    } catch (e) {
      DebugHelper.logError('Error performing bulk action: $e');
      setError('Failed to perform bulk action: $e');
      rethrow;
    }
  }

  // EXPORT DATA FROM ALL PROVIDERS

  Future<String> exportData(String dataType, {List<String>? ids, String format = 'csv'}) async {
    try {
      switch (dataType) {
        case 'users':
          return await _userProvider.exportUsersData(userIds: ids, format: format);
        case 'products':
          return await _productProvider.exportProductsData(productIds: ids, format: format);
        case 'support':
          return await _supportProvider.exportSupportData(requestIds: ids, format: format);
        case 'reports':
          final reports = ids != null 
              ? allReports.where((r) => ids.contains(r['id'])).toList()
              : null;
          return await _reportsProvider.exportReportsData(reports: reports, format: format);
        case 'banners':
          return await _bannerProvider.exportBannersData(bannerIds: ids, format: format);
        case 'chats':
          return await _chatProvider.exportChatsData(chatIds: ids, format: format);
        case 'analytics':
          // Export specific analytics data
          return await _analyticsProvider.exportAnalyticsData('topSearches', format: format);
        default:
          throw Exception('Unknown data type for export: $dataType');
      }
    } catch (e) {
      DebugHelper.logError('Error exporting $dataType data: $e');
      rethrow;
    }
  }

  // HEALTH CHECK

  Map<String, dynamic> getSystemHealth() {
    return {
      'providers': {
        'category': !_categoryProvider.isLoading && _categoryProvider.error == null,
        'user': !_userProvider.isLoading && _userProvider.error == null,
        'product': !_productProvider.isLoading && _productProvider.error == null,
        'reports': !_reportsProvider.isLoading && _reportsProvider.error == null,
        'banner': !_bannerProvider.isLoading && _bannerProvider.error == null,
        'support': !_supportProvider.isLoading && _supportProvider.error == null,
        'chat': !_chatProvider.isLoading && _chatProvider.error == null,
        'analytics': !_analyticsProvider.isLoading && _analyticsProvider.error == null,
      },
      'errors': {
        'category': _categoryProvider.error,
        'user': _userProvider.error,
        'product': _productProvider.error,
        'reports': _reportsProvider.error,
        'banner': _bannerProvider.error,
        'support': _supportProvider.error,
        'chat': _chatProvider.error,
        'analytics': _analyticsProvider.error,
      },
      'lastUpdated': {
        'category': _categoryProvider.lastUpdated,
        'user': _userProvider.lastUpdated,
        'product': _productProvider.lastUpdated,
        'reports': _reportsProvider.lastUpdated,
        'banner': _bannerProvider.lastUpdated,
        'support': _supportProvider.lastUpdated,
        'chat': _chatProvider.lastUpdated,
        'analytics': _analyticsProvider.lastUpdated,
      },
      'isHealthy': !hasAnyErrors(),
    };
  }

  bool hasAnyErrors() {
    return _categoryProvider.error != null ||
           _userProvider.error != null ||
           _productProvider.error != null ||
           _reportsProvider.error != null ||
           _bannerProvider.error != null ||
           _supportProvider.error != null ||
           _chatProvider.error != null ||
           _analyticsProvider.error != null;
  }

  // DATA MANAGEMENT

  void clearAllData() {
    _categoryProvider.clearAllData();
    _userProvider.clearAllUserData();
    _productProvider.clearAllProductData();
    _reportsProvider.clearAllReportsData();
    _bannerProvider.clearAllBannerData();
    _supportProvider.clearAllSupportData();
    _chatProvider.clearAllChatData();
    _analyticsProvider.clearAllAnalyticsData();
    notifyListeners();
  }

  void clearAllErrors() {
    _categoryProvider.clearError();
    _userProvider.clearError();
    _productProvider.clearError();
    _reportsProvider.clearError();
    _bannerProvider.clearError();
    _supportProvider.clearError();
    _chatProvider.clearError();
    _analyticsProvider.clearError();
    clearError();
  }

  // REFRESH ALL DATA

  Future<void> refreshAllData() async {
    await Future.wait([
      _categoryProvider.loadAllCategories(),
      _userProvider.loadAllUsers(),
      _productProvider.loadAllProducts(),
      _reportsProvider.refreshReports(),
      _bannerProvider.loadAllBanners(),
      _supportProvider.refreshSupportRequests(),
      _chatProvider.refreshChats(),
      _analyticsProvider.refreshAnalytics(),
    ]);
  }

  // DISPOSAL

  @override
  void dispose() {
    _categoryProvider.removeListener(_onProviderChanged);
    _userProvider.removeListener(_onProviderChanged);
    _productProvider.removeListener(_onProviderChanged);
    _reportsProvider.removeListener(_onProviderChanged);
    _bannerProvider.removeListener(_onProviderChanged);
    _supportProvider.removeListener(_onProviderChanged);
    _chatProvider.removeListener(_onProviderChanged);
    _analyticsProvider.removeListener(_onProviderChanged);
    
    _categoryProvider.dispose();
    _userProvider.dispose();
    _productProvider.dispose();
    _reportsProvider.dispose();
    _bannerProvider.dispose();
    _supportProvider.dispose();
    _chatProvider.dispose();
    _analyticsProvider.dispose();
    
    super.dispose();
  }
}