import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/providers/product_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/create_product_screen.dart' hide AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Make sure to import your AppColors and AdminDataProvider

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _categoryFilter = 'all';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadAllProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Products Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const CreateProductScreen(),
                    ));
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Product'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters and Search
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Search
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search products...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Status Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Status')),
                              DropdownMenuItem(value: 'active', child: Text('Active')),
                              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                              DropdownMenuItem(value: 'pending', child: Text('Pending')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _statusFilter = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Category Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _categoryFilter,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Categories')),
                              DropdownMenuItem(value: 'Mobiles', child: Text('Mobiles')),
                              DropdownMenuItem(value: 'Computer & Laptop', child: Text('Computers')),
                              DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                              DropdownMenuItem(value: 'Fashion', child: Text('Fashion')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _categoryFilter = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Consumer<ProductProvider>(
                          builder: (context, provider, child) {
                            final filteredProducts = _getFilteredProducts(provider.allProducts);
                            return Text(
                              'Showing ${filteredProducts.length} products',
                              style: const TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Provider.of<ProductProvider>(context, listen: false)
                                    .loadAllProducts();
                              },
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh',
                            ),
                            IconButton(
                              onPressed: () {
                                // Export functionality
                              },
                              icon: const Icon(Icons.download),
                              tooltip: 'Export',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Products Table
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredProducts = _getFilteredProducts(provider.allProducts);
                  final paginatedProducts = _getPaginatedProducts(filteredProducts);

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try adjusting your search or filter criteria',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: Card(
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: false,
                                      onChanged: (value) {
                                        // Select all functionality
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(flex: 2, child: Text('Product', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(child: Text('Category', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(child: Text('Price', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const Expanded(flex: 2, child: Text('Created', style: TextStyle(fontWeight: FontWeight.w600))),
                                    const SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),

                              // Table Body
                              Expanded(
                                child: ListView.separated(
                                  itemCount: paginatedProducts.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final product = paginatedProducts[index];
                                    return _buildProductRow(product, provider);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Pagination
                      if (filteredProducts.length > _itemsPerPage)
                        _buildPagination(filteredProducts.length),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Date Formatting Methods
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }
      // Format: DD/MM/YYYY HH:mm
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatDateRelative(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) {
        // If more than a week old, show full date
        return DateFormat('dd/MM/yyyy').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  // Fixed Safe Image Widget
  Widget _buildSafeImage(String? imageUrl, {double? width, double? height}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width ?? 50,
        height: height ?? 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.background,
        ),
        child: const Icon(Icons.image, color: AppColors.textLight),
      );
    }

    return Container(
      width: width ?? 50,
      height: height ?? 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.background,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.background,
              child: const Icon(Icons.broken_image, color: AppColors.textLight),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppColors.background,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product, ProductProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Checkbox(
            value: false,
            onChanged: (value) {
              // Select item functionality
            },
          ),
          const SizedBox(width: 12),

          // Product Info
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _buildSafeImage(
                  product['imageUrls'] != null && (product['imageUrls'] as List).isNotEmpty
                      ? product['imageUrls'][0]
                      : null,
                  width: 50,
                  height: 50,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['itemTitle'] ?? 'Unknown Product',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${product['sellerName'] ?? 'Unknown Seller'}',
                        style: const TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category
          Expanded(
            child: Text(
              product['categoryName'] ?? product['category'] ?? 'Unknown',
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Price
          Expanded(
            child: Text(
              '\$${(product['price'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Status
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(product['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                product['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                style: TextStyle(
                  color: _getStatusColor(product['status']),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Created Date & Time (Enhanced)
          Expanded(
            flex: 2, // Make this column wider to accommodate date + time
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(product['createdAt']),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateRelative(product['createdAt']),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _viewProduct(product),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: 'View',
                ),
                IconButton(
                  onPressed: () => _editProduct(product),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleProductAction(value, product, provider),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            product['status'] == 'active' 
                                ? Icons.pause_circle_outline 
                                : Icons.play_circle_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(product['status'] == 'active' ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'feature',
                      child: Row(
                        children: [
                          Icon(Icons.star_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Feature'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalItems) {
    final totalPages = (totalItems / _itemsPerPage).ceil();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage).clamp(0, totalItems)} of $totalItems',
              style: const TextStyle(color: AppColors.textMedium),
            ),
            Row(
              children: [
                DropdownButton<int>(
                  value: _itemsPerPage,
                  items: [5, 10, 25, 50].map((items) {
                    return DropdownMenuItem(
                      value: items,
                      child: Text('$items per page'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _itemsPerPage = value!;
                      _currentPage = 1;
                    });
                  },
                  underline: const SizedBox(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _currentPage > 1 ? () {
                    setState(() {
                      _currentPage--;
                    });
                  } : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$_currentPage of $totalPages'),
                IconButton(
                  onPressed: _currentPage < totalPages ? () {
                    setState(() {
                      _currentPage++;
                    });
                  } : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredProducts(List<Map<String, dynamic>> products) {
    return products.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          (product['itemTitle'] ?? '').toLowerCase().contains(_searchQuery) ||
          (product['category'] ?? '').toLowerCase().contains(_searchQuery) ||
          (product['sellerName'] ?? '').toLowerCase().contains(_searchQuery);

      final matchesStatus = _statusFilter == 'all' ||
          product['status'] == _statusFilter;

      final matchesCategory = _categoryFilter == 'all' ||
          product['category'] == _categoryFilter;

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();
  }

  List<Map<String, dynamic>> _getPaginatedProducts(List<Map<String, dynamic>> products) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, products.length);
    return products.sublist(startIndex, endIndex);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textMedium;
    }
  }

  // Helper method for detail rows in the dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Product Details Dialog
  void _viewProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          // maxHeight: 700,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Product Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Product Images
                if (product['imageUrls'] != null && (product['imageUrls'] as List).isNotEmpty)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product['imageUrls'][0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.background,
                            child: const Icon(Icons.broken_image, size: 50, color: AppColors.textLight),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Product Title
                Text(
                  product['itemTitle'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Product Details
                _buildDetailRow('ID', product['id'] ?? 'Unknown'),
                _buildDetailRow('Category', product['categoryName'] ?? product['category'] ?? 'Unknown'),
                _buildDetailRow('Price', '\$${(product['price'] ?? 0).toStringAsFixed(2)}'),
                _buildDetailRow('Status', product['status'] ?? 'Unknown'),
                _buildDetailRow('Condition', product['condition'] ?? 'Unknown'),
                _buildDetailRow('Brand', product['brand'] ?? 'Unknown'),
                _buildDetailRow('Seller', product['sellerName'] ?? 'Unknown'),
                _buildDetailRow('Seller Type', product['sellerType'] ?? 'Unknown'),
                _buildDetailRow('Created', _formatDate(product['createdAt'])),
                _buildDetailRow('Time Ago', _formatDateRelative(product['createdAt'])),
                if (product['updatedAt'] != null)
                  _buildDetailRow('Last Updated', _formatDate(product['updatedAt'])),
                _buildDetailRow('Views', '${product['viewCount'] ?? product['views'] ?? 0}'),
                _buildDetailRow('Likes', '${product['favoriteCount'] ?? product['likes'] ?? 0}'),
                if (product['locationAddress'] != null)
                  _buildDetailRow('Location', product['locationAddress']),
                if (product['dimensions'] != null && product['dimensions'].toString().isNotEmpty)
                  _buildDetailRow('Dimensions', product['dimensions']),
                if (product['color'] != null && product['color'].toString().isNotEmpty)
                  _buildDetailRow('Color', product['color']),
                _buildDetailRow('Images', '${(product['imageUrls'] as List?)?.length ?? 0}'),
                
                const SizedBox(height: 12),
                
                // Description
                if (product['description'] != null && product['description'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMedium,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          product['description'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editProduct(Map<String, dynamic> product) {
    // Navigate to edit product screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit product functionality coming soon')),
    );
  }

  void _handleProductAction(String action, Map<String, dynamic> product, ProductProvider provider) {
    switch (action) {
      case 'toggle_status':
        final newStatus = product['status'] == 'active' ? 'inactive' : 'active';
        provider.updateProductStatus(product['id'], newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product ${newStatus == 'active' ? 'activated' : 'deactivated'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case 'feature':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feature product functionality coming soon')),
        );
        break;
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate product functionality coming soon')),
        );
        break;
      case 'delete':
        _confirmDeleteProduct(product, provider);
        break;
    }
  }

  void _confirmDeleteProduct(Map<String, dynamic> product, ProductProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product['itemTitle']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.deleteProduct(product['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product deleted successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
