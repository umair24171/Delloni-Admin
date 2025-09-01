// product_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'base_admin_provider.dart';

class ProductProvider extends BaseAdminProvider {
  // Product data
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _recentProducts = [];
  
  // Product statistics
  int _totalProducts = 0;
  int _todayNewProducts = 0;
  int _newListingsThisWeek = 0;
  double _listingGrowthPercentage = 0.0;
  String _listingTrend = 'up';

  // Getters
  List<Map<String, dynamic>> get allProducts => _allProducts;
  List<Map<String, dynamic>> get recentProducts => _recentProducts;
  int get totalProducts => _totalProducts;
  int get todayNewProducts => _todayNewProducts;
  int get newListingsThisWeek => _newListingsThisWeek;
  double get listingGrowthPercentage => _listingGrowthPercentage;
  String get listingTrend => _listingTrend;

  // LOAD PRODUCT DATA

  Future<void> loadAllProducts() async {
    if (isLoading) return;
    
    setLoading(true);
    try {
      DebugHelper.logInfo('Loading products from Firestore...');
      final productsSnapshot = await firestore
          .collection('items')
          .get();

      _allProducts = productsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      _totalProducts = _allProducts.length;
      
      DebugHelper.logInfo('Loaded ${_allProducts.length} products from Firestore');
      if (_allProducts.isNotEmpty) {
        DebugHelper.logInfo('First product: ${_allProducts.first['itemTitle'] ?? 'No title'}');
      }
      
      updateLastUpdated();
      notifyListeners();
    } catch (e) {
      DebugHelper.logError('Error loading products: $e');
      setError('Failed to load products: $e');
    }
    setLoading(false);
  }

  Future<void> loadProductStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month - 1, now.day);

      // Get all products
      final productsSnapshot = await firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .get();
      _totalProducts = productsSnapshot.docs.length;

      // Calculate today's new products
      final todayProductsQuery = await firestore
          .collection('items')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('status', isEqualTo: 'active')
          .get();
      _todayNewProducts = todayProductsQuery.docs.length;

      // Calculate weekly new products
      final weeklyProductsQuery = await firestore
          .collection('items')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('status', isEqualTo: 'active')
          .get();
      _newListingsThisWeek = weeklyProductsQuery.docs.length;

      // Calculate monthly growth
      final monthlyProductsQuery = await firestore
          .collection('items')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('status', isEqualTo: 'active')
          .get();
      final monthlyNewProducts = monthlyProductsQuery.docs.length;

      // Calculate growth percentage
      final previousMonthProducts = _totalProducts - monthlyNewProducts;
      if (previousMonthProducts > 0) {
        _listingGrowthPercentage = (monthlyNewProducts / previousMonthProducts) * 100;
        _listingTrend = _listingGrowthPercentage > 0 ? 'up' : 'down';
      }

      // Get recent products
      final recentProductsSnapshot = await firestore
          .collection('items')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      _recentProducts = recentProductsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      notifyListeners();
    } catch (e) {
      DebugHelper.logError('Error loading product stats: $e');
    }
  }

  // PRODUCT MANAGEMENT OPERATIONS

 Future<void> createProduct(Map<String, dynamic> productData) async {
  setLoading(true);
  try {
    // Generate unique itemId if not provided
    final itemId = productData['itemId'] ?? const Uuid().v4();
    
    // Prepare complete product data with all required fields
    final completeProductData = {
      ...productData,
      'itemId': itemId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      
      // Location fields (set defaults if not provided)
      'latitude': productData['latitude'] ?? 0.0,
      'longitude': productData['longitude'] ?? 0.0,
      'locationAddress': productData['locationAddress'] ?? '',
      'cityName': productData['cityName'] ?? '',
      'cityId': productData['cityId'] ?? '',
      'districtName': productData['districtName'] ?? '',
      'districtId': productData['districtId'] ?? '',
      
      // Media and visual fields
      'imageUrls': productData['imageUrls'] ?? [],
      'photoCount': productData['photoCount'] ?? 0,
      
      // Product status and promotion fields
      'status': productData['status'] ?? 'active',
      'isFeatured': productData['isFeatured'] ?? false,
      'isPromoted': productData['isPromoted'] ?? false,
      'isRealEstate': productData['isRealEstate'] ?? false,
      
      // Category fields
      'category': productData['category'] ?? '',
      'categoryName': productData['categoryName'] ?? '',
      'categoryTemplateName': productData['categoryTemplateName'] ?? '',
      'categoryFieldTemplate': productData['categoryFieldTemplate'] ?? [],
      'categorySpecificFields': productData['categorySpecificFields'] ?? {},
      'hasCustomFields': productData['hasCustomFields'] ?? false,
      
      // Product details
      'condition': productData['condition'] ?? 'used',
      'brand': productData['brand'] ?? '',
      'color': productData['color'] ?? '',
      'dimensions': productData['dimensions'] ?? '',
      'shippingOption': productData['shippingOption'] ?? 'Both',
      'allowPriceNegotiation': productData['allowPriceNegotiation'] ?? false,
      
      // Seller information
      'sellerType': productData['sellerType'] ?? 'individual',
      'sellerName': productData['sellerName'] ?? '',
      
      // Engagement metrics (initialize to 0 for new products)
      'views': 0,
      'viewCount': 0,
      'likes': 0,
      'favoriteCount': 0,
    };

    final docRef = await firestore.collection('items').add(completeProductData);

    // Update local data with the document ID
    completeProductData['id'] = docRef.id;
    completeProductData['createdAt'] = Timestamp.now();
    completeProductData['updatedAt'] = Timestamp.now();
    
    _allProducts.insert(0, completeProductData);
    _totalProducts = _allProducts.length;
    updateLastUpdated();
    notifyListeners();

    // Log admin action
    await logAdminAction(
      'create_product', 
      docRef.id, 
      'Product created by admin: ${completeProductData['itemTitle']}', 
      targetType: 'product'
    );
  } catch (e) {
    DebugHelper.logError('Error creating product: $e');
    setError('Failed to create product: $e');
    rethrow;
  }
  setLoading(false);
}

  Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      await firestore.collection('items').doc(productId).update({
        ...productData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final productIndex = _allProducts.indexWhere((product) => product['id'] == productId);
      if (productIndex != -1) {
        _allProducts[productIndex] = {
          ..._allProducts[productIndex],
          ...productData,
          'id': productId,
          'updatedAt': Timestamp.now(),
        };
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction('update_product', productId, 'Product updated by admin', targetType: 'product');
    } catch (e) {
      DebugHelper.logError('Error updating product: $e');
      setError('Failed to update product: $e');
      rethrow;
    }
  }

  Future<void> updateProductStatus(String productId, String status) async {
    try {
      await firestore.collection('items').doc(productId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final productIndex = _allProducts.indexWhere((product) => product['id'] == productId);
      if (productIndex != -1) {
        _allProducts[productIndex]['status'] = status;
        _allProducts[productIndex]['updatedAt'] = Timestamp.now();
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction('update_product_status', productId, 'Product status changed to: $status', targetType: 'product');
    } catch (e) {
      DebugHelper.logError('Error updating product status: $e');
      setError('Failed to update product status: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      // Get product data for logging
      final productIndex = _allProducts.indexWhere((product) => product['id'] == productId);
      final productTitle = productIndex != -1 ? _allProducts[productIndex]['itemTitle'] ?? 'Unknown' : 'Unknown';

      await firestore.collection('items').doc(productId).delete();
      
      if (productIndex != -1) {
        _allProducts.removeAt(productIndex);
        _totalProducts = _allProducts.length;
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction('delete_product', productId, 'Product deleted by admin: $productTitle', targetType: 'product');
    } catch (e) {
      DebugHelper.logError('Error deleting product: $e');
      setError('Failed to delete product: $e');
    }
  }

  // BULK OPERATIONS

  Future<void> bulkUpdateProductStatus(List<String> productIds, String status) async {
    try {
      final batch = firestore.batch();
      
      for (final productId in productIds) {
        final productRef = firestore.collection('items').doc(productId);
        batch.update(productRef, {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      // Update local data
      for (final productId in productIds) {
        final productIndex = _allProducts.indexWhere((product) => product['id'] == productId);
        if (productIndex != -1) {
          _allProducts[productIndex]['status'] = status;
          _allProducts[productIndex]['updatedAt'] = Timestamp.now();
        }
      }
      
      updateLastUpdated();
      notifyListeners();
      
      // Log bulk action
      await logAdminAction(
        'bulk_update_product_status',
        productIds.join(','),
        'Bulk updated ${productIds.length} products to status: $status',
        targetType: 'product'
      );
      
    } catch (e) {
      DebugHelper.logError('Error bulk updating product status: $e');
      setError('Failed to bulk update product status: $e');
      rethrow;
    }
  }

  Future<void> bulkDeleteProducts(List<String> productIds) async {
    try {
      final batch = firestore.batch();
      
      for (final productId in productIds) {
        final productRef = firestore.collection('items').doc(productId);
        batch.delete(productRef);
      }
      
      await batch.commit();
      
      // Remove from local data
      _allProducts.removeWhere((product) => productIds.contains(product['id']));
      _totalProducts = _allProducts.length;
      updateLastUpdated();
      notifyListeners();
      
      // Log bulk action
      await logAdminAction(
        'bulk_delete_products',
        productIds.join(','),
        'Bulk deleted ${productIds.length} products',
        targetType: 'product'
      );
      
    } catch (e) {
      DebugHelper.logError('Error bulk deleting products: $e');
      setError('Failed to bulk delete products: $e');
      rethrow;
    }
  }

  // FEATURED PRODUCTS MANAGEMENT

  Future<void> setProductFeatured(String productId, bool isFeatured, {DateTime? featuredUntil}) async {
    try {
      Map<String, dynamic> updateData = {
        'isFeatured': isFeatured,
        'featuredUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (isFeatured && featuredUntil != null) {
        updateData['featuredUntil'] = Timestamp.fromDate(featuredUntil);
      } else if (!isFeatured) {
        updateData['featuredUntil'] = null;
      }

      await firestore.collection('items').doc(productId).update(updateData);
      
      final productIndex = _allProducts.indexWhere((product) => product['id'] == productId);
      if (productIndex != -1) {
        _allProducts[productIndex]['isFeatured'] = isFeatured;
        _allProducts[productIndex]['featuredUpdatedAt'] = Timestamp.now();
        if (featuredUntil != null) {
          _allProducts[productIndex]['featuredUntil'] = Timestamp.fromDate(featuredUntil);
        }
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction(
        isFeatured ? 'feature_product' : 'unfeature_product', 
        productId, 
        isFeatured ? 'Product set as featured' : 'Product removed from featured',
        targetType: 'product'
      );
    } catch (e) {
      DebugHelper.logError('Error updating product featured status: $e');
      setError('Failed to update product featured status: $e');
    }
  }

  List<Map<String, dynamic>> getFeaturedProducts() {
    final now = Timestamp.now();
    return _allProducts.where((product) {
      final isFeatured = product['isFeatured'] == true;
      final featuredUntil = product['featuredUntil'] as Timestamp?;
      
      if (!isFeatured) return false;
      if (featuredUntil == null) return true;
      
      return featuredUntil.compareTo(now) > 0; // Not expired
    }).toList();
  }

  // SEARCH AND FILTER

  List<Map<String, dynamic>> searchProducts(String query) {
    if (query.isEmpty) return _allProducts;
    
    final lowercaseQuery = query.toLowerCase();
    return _allProducts.where((product) {
      final title = (product['itemTitle'] as String? ?? '').toLowerCase();
      final description = (product['description'] as String? ?? '').toLowerCase();
      final category = (product['categoryName'] as String? ?? '').toLowerCase();
      final brand = (product['brand'] as String? ?? '').toLowerCase();
      final sellerId = (product['sellerId'] as String? ?? '').toLowerCase();
      
      return title.contains(lowercaseQuery) ||
             description.contains(lowercaseQuery) ||
             category.contains(lowercaseQuery) ||
             brand.contains(lowercaseQuery) ||
             sellerId.contains(lowercaseQuery);
    }).toList();
  }

  List<Map<String, dynamic>> filterProducts({
    String? status,
    String? category,
    String? sellerId,
    double? minPrice,
    double? maxPrice,
    DateTime? startDate,
    DateTime? endDate,
    bool? isFeatured,
  }) {
    return _allProducts.where((product) {
      // Status filter
      if (status != null && product['status'] != status) {
        return false;
      }
      
      // Category filter
      if (category != null && product['category'] != category) {
        return false;
      }
      
      // Seller filter
      if (sellerId != null && product['sellerId'] != sellerId) {
        return false;
      }
      
      // Featured filter
      if (isFeatured != null && product['isFeatured'] != isFeatured) {
        return false;
      }
      
      // Price filters
      final price = product['price'] as num?;
      if (price != null) {
        if (minPrice != null && price < minPrice) return false;
        if (maxPrice != null && price > maxPrice) return false;
      }
      
      // Date filters
      final createdAt = product['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final date = createdAt.toDate();
        if (startDate != null && date.isBefore(startDate)) return false;
        if (endDate != null && date.isAfter(endDate)) return false;
      }
      
      return true;
    }).toList();
  }

  // CATEGORY ANALYTICS

  Map<String, int> getProductCountByCategory() {
    final categoryCount = <String, int>{};
    
    for (final product in _allProducts) {
      final categoryName = product['categoryName'] as String? ?? 'Unknown';
      categoryCount[categoryName] = (categoryCount[categoryName] ?? 0) + 1;
    }
    
    return categoryCount;
  }

  Map<String, int> getProductCountByStatus() {
    final statusCount = <String, int>{};
    
    for (final product in _allProducts) {
      final status = product['status'] as String? ?? 'unknown';
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }
    
    return statusCount;
  }

  List<Map<String, dynamic>> getTopSellersByProductCount() {
    final sellerCount = <String, int>{};
    final sellerData = <String, Map<String, dynamic>>{};
    
    for (final product in _allProducts) {
      final sellerId = product['sellerId'] as String?;
      if (sellerId != null) {
        sellerCount[sellerId] = (sellerCount[sellerId] ?? 0) + 1;
        if (!sellerData.containsKey(sellerId)) {
          sellerData[sellerId] = {
            'sellerId': sellerId,
            'sellerName': product['sellerName'] ?? 'Unknown',
            'sellerEmail': product['sellerEmail'] ?? '',
          };
        }
      }
    }
    
    final topSellers = sellerCount.entries
        .map((entry) => {
              ...sellerData[entry.key]!,
              'productCount': entry.value,
            })
        .toList();
    
    topSellers.sort((a, b) => (b['productCount'] as int).compareTo(a['productCount'] as int));
    
    return topSellers.take(10).toList();
  }

  // EXPORT AND REPORTING

  Future<String> exportProductsData({
    List<String>? productIds,
    String format = 'csv',
  }) async {
    try {
      final productsToExport = productIds != null 
          ? _allProducts.where((product) => productIds.contains(product['id'])).toList()
          : _allProducts;
      
      if (format == 'csv') {
        final csv = StringBuffer();
        
        // CSV Headers
        csv.writeln('ID,Title,Category,Brand,Price,Status,Seller ID,Seller Name,Featured,Created At');
        
        // CSV Data
        for (final product in productsToExport) {
          csv.writeln([
            product['id'],
            product['itemTitle'] ?? '',
            product['categoryName'] ?? '',
            product['brand'] ?? '',
            product['price'] ?? '',
            product['status'] ?? '',
            product['sellerId'] ?? '',
            product['sellerName'] ?? '',
            product['isFeatured'] == true ? 'Yes' : 'No',
            formatDate(product['createdAt']),
          ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
        }
        
        return csv.toString();
      }
      
      return '';
      
    } catch (e) {
      DebugHelper.logError('Error exporting products data: $e');
      rethrow;
    }
  }

  // STATISTICS

  Map<String, dynamic> getProductStatistics() {
    final activeProducts = _allProducts.where((product) => product['status'] == 'active').length;
    final pendingProducts = _allProducts.where((product) => product['status'] == 'pending').length;
    final inactiveProducts = _allProducts.where((product) => product['status'] == 'inactive').length;
    final featuredProducts = getFeaturedProducts().length;

    // Calculate average price
    double totalPrice = 0;
    int priceCount = 0;
    
    for (final product in _allProducts) {
      final price = product['price'];
      if (price != null && price is num) {
        totalPrice += price.toDouble();
        priceCount++;
      }
    }

    final averagePrice = priceCount > 0 ? totalPrice / priceCount : 0;

    return {
      'totalProducts': _totalProducts,
      'activeProducts': activeProducts,
      'pendingProducts': pendingProducts,
      'inactiveProducts': inactiveProducts,
      'featuredProducts': featuredProducts,
      'averagePrice': averagePrice,
      'totalValue': totalPrice,
      'categoryCount': getProductCountByCategory().length,
    };
  }

  // VALIDATION

  Future<bool> validateProductData(Map<String, dynamic> productData) async {
    try {
      // Check required fields
      final requiredFields = ['itemTitle', 'description', 'price', 'category', 'sellerId'];
      
      for (final field in requiredFields) {
        if (!productData.containsKey(field) || productData[field] == null || productData[field].toString().isEmpty) {
          setError('Missing required field: $field');
          return false;
        }
      }
      
      // Validate price
      final price = productData['price'];
      if (price is! num || price <= 0) {
        setError('Price must be a positive number');
        return false;
      }
      
      // Validate seller exists
      final sellerId = productData['sellerId'];
      final sellerDoc = await firestore.collection('users').doc(sellerId).get();
      if (!sellerDoc.exists) {
        setError('Seller does not exist');
        return false;
      }
      
      return true;
    } catch (e) {
      DebugHelper.logError('Error validating product data: $e');
      setError('Validation error: $e');
      return false;
    }
  }

  // DATA MANAGEMENT

  void clearAllProductData() {
    _allProducts.clear();
    _recentProducts.clear();
    _totalProducts = 0;
    _todayNewProducts = 0;
    _newListingsThisWeek = 0;
    _listingGrowthPercentage = 0.0;
    _listingTrend = 'up';
    notifyListeners();
  }
}