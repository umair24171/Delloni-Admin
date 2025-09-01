import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/providers/category_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/create_categories_screen.dart';
import 'package:delloniweb/screens/dashboard_overview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends State<CategoriesManagementScreen> {
  String _searchQuery = '';
  String _levelFilter = 'all';
  String _statusFilter = 'all';
  Map<String, bool> _expandedCategories = {};
  Set<String> _selectedCategories = {}; // For bulk delete
  bool _isSelectMode = false; // Toggle select mode
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadAllCategories();
      _setupScrollListener();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoadingMore) {
        _loadMoreCategories();
      }
    });
  }

  Future<void> _loadMoreCategories() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Provider.of<CategoryProvider>(context, listen: false).loadMoreCategories();

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                  Icons.category_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Categories Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                _buildStatsCards(),
                const SizedBox(width: 16),
                
                // Bulk Delete Button (shown only in select mode)
                if (_isSelectMode && _selectedCategories.isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: _bulkDeleteCategories,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: Text('Delete (${_selectedCategories.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Select Mode Toggle
                IconButton(
                  onPressed: _toggleSelectMode,
                  icon: Icon(_isSelectMode ? Icons.close : Icons.checklist),
                  tooltip: _isSelectMode ? 'Exit Select Mode' : 'Select Multiple',
                ),
                const SizedBox(width: 8),
                
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateCategoryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Category'),
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
                              hintText: 'Search categories by name...',
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

                        // Level Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _levelFilter,
                            decoration: const InputDecoration(
                              labelText: 'Category Level',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Levels')),
                              DropdownMenuItem(value: 'main', child: Text('Main Categories')),
                              DropdownMenuItem(value: 'sub', child: Text('Sub Categories')),
                              DropdownMenuItem(value: 'subsub', child: Text('Sub-Sub Categories')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _levelFilter = value!;
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
                            ],
                            onChanged: (value) {
                              setState(() {
                                _statusFilter = value!;
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
                        Consumer<CategoryProvider>(
                          builder: (context, provider, child) {
                            final filteredCategories = _getFilteredCategories(provider.allCategories);
                            return Text(
                              'Showing ${filteredCategories.length} categories',
                              style: const TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                        Row(
                          children: [
                            // Select All/None buttons (shown only in select mode)
                            if (_isSelectMode) ...[
                              TextButton.icon(
                                onPressed: _selectAllCategories,
                                icon: const Icon(Icons.select_all, size: 18),
                                label: const Text('Select All'),
                              ),
                              TextButton.icon(
                                onPressed: _clearSelection,
                                icon: const Icon(Icons.clear, size: 18),
                                label: const Text('Clear'),
                              ),
                            ],
                            
                            TextButton.icon(
                              onPressed: _expandAll,
                              icon: const Icon(Icons.expand_more, size: 18),
                              label: const Text('Expand All'),
                            ),
                            TextButton.icon(
                              onPressed: _collapseAll,
                              icon: const Icon(Icons.expand_less, size: 18),
                              label: const Text('Collapse All'),
                            ),
                            IconButton(
                              onPressed: () {
                                Provider.of<CategoryProvider>(context, listen: false)
                                    .loadAllCategories();
                              },
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh',
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

            // Categories Tree View
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredCategories = _getFilteredCategories(provider.allCategories);
                  final mainCategories = _getMainCategories(filteredCategories);

                  if (mainCategories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No categories found',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first category to organize products',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CreateCategoryScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Category'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: mainCategories.length + 1, // +1 for loading indicator
                      itemBuilder: (context, index) {
                        if (index == mainCategories.length) {
                          // Show loading indicator at the bottom
                          return _isLoadingMore
                              ? Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                )
                              : const SizedBox.shrink();
                        }
                        final category = mainCategories[index];
                        return _buildCategoryTreeItem(category, provider.allCategories, 0);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
      return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        final totalCategories = provider.allCategories.length;
        final mainCategories = provider.allCategories.where((c) => c['parentId'] == null).length;
        final activeCategories = provider.allCategories.where((c) => c['isActive'] == true).length;
        
        return Row(
          children: [
            _buildStatCard('Total', totalCategories.toString(), Icons.category, AppColors.primary),
            const SizedBox(width: 12),
            _buildStatCard('Main', mainCategories.toString(), Icons.folder, AppColors.success),
            const SizedBox(width: 12),
            _buildStatCard('Active', activeCategories.toString(), Icons.visibility, AppColors.info),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTreeItem(Map<String, dynamic> category, List<Map<String, dynamic>> allCategories, int level) {
    final categoryId = category['id'];
    final isExpanded = _expandedCategories[categoryId] ?? false;
    final children = _getCategoryChildren(categoryId, allCategories);
    final hasChildren = children.isNotEmpty;
    final isActive = category['isActive'] == true;
    final isSelected = _selectedCategories.contains(categoryId);

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: level * 24.0, bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _isSelectMode ? () => _toggleCategorySelection(categoryId) : 
                   hasChildren ? () {
              setState(() {
                _expandedCategories[categoryId] = !isExpanded;
              });
            } : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox (shown only in select mode)
                  if (_isSelectMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleCategorySelection(categoryId),
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  // Expand/Collapse Icon
                  if (hasChildren && !_isSelectMode)
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                      color: AppColors.textMedium,
                    )
                  else if (!_isSelectMode)
                    const SizedBox(width: 24),
                  
                  const SizedBox(width: 8),
                  
                  // Category Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(level).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: category['iconUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SafeNetworkImage(
                              imageUrl: category['iconUrl'],
                              fit: BoxFit.cover,
                              errorWidget: Icon(
                                _getCategoryIcon(level),
                                color: _getCategoryColor(level),
                                size: 20,
                              ),
                            ),
                          )
                        : Icon(
                            _getCategoryIcon(level),
                            color: _getCategoryColor(level),
                            size: 20,
                          ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Category Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name'] ?? 'Unnamed Category',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getLevelColor(level).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _getLevelText(level),
                                style: TextStyle(
                                  color: _getLevelColor(level),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (hasChildren)
                              Text(
                                '${children.length} children',
                                style: const TextStyle(
                                  color: AppColors.textMedium,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        color: isActive ? AppColors.success : AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Actions Menu (hidden in select mode)
                  if (!_isSelectMode)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleCategoryAction(value, category),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: const [
                              Icon(Icons.visibility_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: const [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (level < 6)
                          PopupMenuItem(
                            value: 'add_child',
                            child: Row(
                              children: const [
                                Icon(Icons.add_circle_outline, size: 16),
                                SizedBox(width: 8),
                                Text('Add Subcategory'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Row(
                            children: [
                              Icon(
                                isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(isActive ? 'Deactivate' : 'Activate'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: const [
                              Icon(Icons.delete_outline, size: 16, color: AppColors.error),
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
          ),
        ),
        
        // Children Categories
        if (hasChildren && isExpanded && !_isSelectMode)
          ...children.map((child) => _buildCategoryTreeItem(child, allCategories, level + 1)),
      ],
    );
  }

  // Selection Mode Methods
  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedCategories.clear();
      }
    });
  }

  void _toggleCategorySelection(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  void _selectAllCategories() {
    setState(() {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      final filteredCategories = _getFilteredCategories(provider.allCategories);
      _selectedCategories.addAll(filteredCategories.map((c) => c['id'].toString()));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCategories.clear();
    });
  }

  // Enhanced Delete Methods
  void _bulkDeleteCategories() {
    if (_selectedCategories.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Categories'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${_selectedCategories.length} selected categories?'),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone and will also delete all subcategories.',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performBulkDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _performBulkDelete() async {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete categories one by one
      for (String categoryId in _selectedCategories) {
        await provider.deleteCategory(categoryId);
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Clear selection and exit select mode
      setState(() {
        _selectedCategories.clear();
        _isSelectMode = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedCategories.length} categories deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      // Reload categories
      provider.loadAllCategories();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting categories: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _deleteCategory(Map<String, dynamic> category) {
    final hasChildren = _getCategoryChildren(category['id'], 
        Provider.of<CategoryProvider>(context, listen: false).allCategories).isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${category['name']}"?'),
            if (hasChildren) ...[
              const SizedBox(height: 12),
              const Text(
                'Warning: This category has subcategories. Deleting it will also delete all its subcategories.',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: AppColors.textMedium),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performSingleDelete(category);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performSingleDelete(Map<String, dynamic> category) async {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    
    try {
      await provider.deleteCategory(category['id']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Reload categories
      provider.loadAllCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting category: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getLevelText(int level) {
    switch (level) {
      case 0:
        return 'MAIN';
      case 1:
        return 'SUB';
      case 2:
        return 'SUB-SUB';
      case 3:
        return 'LEVEL-3';
      case 4:
        return 'LEVEL-4';
      case 5:
        return 'LEVEL-5';
      case 6:
        return 'FINAL';
      default:
        return 'LEVEL-$level';
    }
  }

  // Helper Methods (keeping existing ones)
  List<Map<String, dynamic>> _getFilteredCategories(List<Map<String, dynamic>> categories) {
    return categories.where((category) {
      final name = (category['name'] ?? '').toLowerCase();
      final description = (category['description'] ?? '').toLowerCase();
      
      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          description.contains(_searchQuery);

      bool matchesLevel;
      if (_levelFilter == 'all') {
        matchesLevel = true;
      } else if (_levelFilter == 'main') {
        matchesLevel = category['parentId'] == null;
      } else if (_levelFilter == 'sub') {
        // Include all non-main categories
        matchesLevel = category['parentId'] != null;
      } else if (_levelFilter == 'subsub') {
        // Check if parent is a sub-category
        final parentId = category['parentId'];
        if (parentId != null) {
          final parent = categories.firstWhere(
            (c) => c['id'] == parentId,
            orElse: () => {'parentId': null},
          );
          matchesLevel = parent['parentId'] != null;
        } else {
          matchesLevel = false;
        }
      } else {
        matchesLevel = true;
      }

      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'active' && category['isActive'] == true) ||
          (_statusFilter == 'inactive' && category['isActive'] != true);

      return matchesSearch && matchesLevel && matchesStatus;
    }).toList();
  }

  List<Map<String, dynamic>> _getMainCategories(List<Map<String, dynamic>> categories) {
    var mainCats = categories.where((category) => category['parentId'] == null).toList();
    
    // Sort by order first, then by creation date (newest first)
    mainCats.sort((a, b) {
      final orderA = a['order'] ?? 0;
      final orderB = b['order'] ?? 0;
      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }
      
      final dateA = a['createdAt'] as Timestamp?;
      final dateB = b['createdAt'] as Timestamp?;
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA); // Newest first
      }
      return 0;
    });
    
    return mainCats;
  }

  List<Map<String, dynamic>> _getCategoryChildren(String parentId, List<Map<String, dynamic>> categories) {
    var children = categories.where((category) => category['parentId'] == parentId).toList();
    
    // Sort by order first, then by creation date (newest first)
    children.sort((a, b) {
      final orderA = a['order'] ?? 0;
      final orderB = b['order'] ?? 0;
      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }
      
      final dateA = a['createdAt'] as Timestamp?;
      final dateB = b['createdAt'] as Timestamp?;
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA); // Newest first
      }
      return 0;
    });
    
    return children;
  }

  int _getParentLevel(Map<String, dynamic> category, List<Map<String, dynamic>> categories) {
    if (category['parentId'] == null) return 0;
    
    final parent = categories.firstWhere(
      (c) => c['id'] == category['parentId'],
      orElse: () => {'parentId': null},
    );
    
    return parent['parentId'] == null ? 0 : 1;
  }

  Color _getCategoryColor(int level) {
    switch (level) {
      case 0:
        return AppColors.primary;
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.warning;
      default:
        return AppColors.textMedium;
    }
  }

  IconData _getCategoryIcon(int level) {
    switch (level) {
      case 0:
        return Icons.folder;
      case 1:
        return Icons.folder_open;
      case 2:
        return Icons.insert_drive_file;
      default:
        return Icons.category;
    }
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return AppColors.primary;
      case 1:
        return AppColors.info;
      case 2:
        return AppColors.secondary;
      default:
        return AppColors.textMedium;
    }
  }

  void _expandAll() {
    setState(() {
      for (var category in Provider.of<CategoryProvider>(context, listen: false).allCategories) {
        _expandedCategories[category['id']] = true;
      }
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedCategories.clear();
    });
  }

  void _handleCategoryAction(String action, Map<String, dynamic> category) {
    switch (action) {
      case 'view':
        _viewCategoryDetails(category);
        break;
      case 'edit':
        _editCategory(category);
        break;
      case 'add_child':
        _addSubcategory(category);
        break;
      case 'toggle_status':
        _toggleCategoryStatus(category);
        break;
      case 'delete':
        _deleteCategory(category);
        break;
    }
  }

  void _viewCategoryDetails(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Category Details',
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
              
              if (category['iconUrl'] != null)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      category['iconUrl'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              _buildDetailRow('Name', category['name'] ?? 'Unknown'),
              _buildDetailRow('Description', category['description'] ?? 'No description'),
              _buildDetailRow('Level', _getLevelText(_getCategoryLevel(category))),
              _buildDetailRow('Status', category['isActive'] == true ? 'Active' : 'Inactive'),
              _buildDetailRow('Order', category['order']?.toString() ?? '0'),
              _buildDetailRow('Created', _formatDate(category['createdAt'])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  int _getCategoryLevel(Map<String, dynamic> category) {
    if (category['parentId'] == null) return 0;
    // This would need to be calculated based on parent hierarchy
    return 1; // Simplified for demo
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _editCategory(Map<String, dynamic> category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateCategoryScreen(editingCategory: category),
      ),
    );
  }

  void _addSubcategory(Map<String, dynamic> parentCategory) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateCategoryScreen(parentCategory: parentCategory),
      ),
    );
  }

  void _toggleCategoryStatus(Map<String, dynamic> category) {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    provider.updateCategoryStatus(category['id'], !(category['isActive'] ?? false));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(category['isActive'] == true ? 'Category deactivated' : 'Category activated'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}