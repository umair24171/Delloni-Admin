import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/providers/banner_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/create_banner_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({Key? key}) : super(key: key);

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  int _currentPage = 1;
  int _itemsPerPage = 12;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BannerProvider>(context, listen: false).loadAllBanners();
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
                  Icons.view_carousel_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Banners Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                _buildStatsCards(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateBannerScreen()));
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Create Banner'),
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
                              hintText: 'Search banners by title or description...',
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
                              DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                              DropdownMenuItem(value: 'expired', child: Text('Expired')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _statusFilter = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Type Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _typeFilter,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Types')),
                              DropdownMenuItem(value: 'hero', child: Text('Hero Banner')),
                              DropdownMenuItem(value: 'promotional', child: Text('Promotional')),
                              DropdownMenuItem(value: 'category', child: Text('Category')),
                              DropdownMenuItem(value: 'product', child: Text('Product')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _typeFilter = value!;
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
                        Consumer<BannerProvider>(
                          builder: (context, provider, child) {
                            final filteredBanners = _getFilteredBanners(provider.allBanners);
                            return Text(
                              'Showing ${filteredBanners.length} banners',
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
                                Provider.of<BannerProvider>(context, listen: false)
                                    .loadAllBanners();
                              },
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh',
                            ),
                            // IconButton(
                            //   onPressed: () {
                            //     // Export functionality
                            //   },
                            //   icon: const Icon(Icons.download),
                            //   tooltip: 'Export',
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Banners Grid
            Expanded(
              child: Consumer<BannerProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredBanners = _getFilteredBanners(provider.allBanners);
                  final paginatedBanners = _getPaginatedBanners(filteredBanners);

                  if (filteredBanners.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.view_carousel_outlined,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No banners found',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first banner to get started',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateBannerScreen()));
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Banner'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: paginatedBanners.length,
                          itemBuilder: (context, index) {
                            final banner = paginatedBanners[index];
                            return _buildBannerCard(banner, provider);
                          },
                        ),
                      ),

                      // Pagination
                      if (filteredBanners.length > _itemsPerPage)
                        _buildPagination(filteredBanners.length),
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

  Widget _buildStatsCards() {
    return Consumer<BannerProvider>(
      builder: (context, provider, child) {
        final totalBanners = provider.allBanners.length;
        final activeBanners = provider.allBanners.where((b) => b['isActive'] == true).length;
        final scheduledBanners = provider.allBanners.where((b) => _isBannerScheduled(b)).length;
        
        return Row(
          children: [
            _buildStatCard('Total', totalBanners.toString(), Icons.view_carousel, AppColors.primary),
            const SizedBox(width: 12),
            _buildStatCard('Active', activeBanners.toString(), Icons.visibility, AppColors.success),
            const SizedBox(width: 12),
            _buildStatCard('Scheduled', scheduledBanners.toString(), Icons.schedule, AppColors.info),
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

    Widget _buildBannerCard(Map<String, dynamic> banner, BannerProvider provider) {
    final isActive = banner['isActive'] == true;
    final isExpired = _isBannerExpired(banner);
    final isScheduled = _isBannerScheduled(banner);
    
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: AppColors.background,
                image: banner['imageUrl'] != null
                    ? DecorationImage(
                        image: NetworkImage(banner['imageUrl']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (banner['imageUrl'] == null)
                    const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: AppColors.textLight,
                      ),
                    ),
                  
                  // Status Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBannerStatusColor(banner).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getBannerStatus(banner).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Priority Badge
                  if (banner['priority'] != null && banner['priority'] > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'P${banner['priority']}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Banner Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner['title'] ?? 'Untitled Banner',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner['description'] ?? 'No description',
                    style: const TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getBannerTypeColor(banner['type']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (banner['type'] ?? 'general').toUpperCase(),
                          style: TextStyle(
                            color: _getBannerTypeColor(banner['type']),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleBannerAction(value, banner, provider),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: const [
                                Icon(Icons.visibility_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('View'),
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
                          PopupMenuItem(
                            value: 'toggle_status',
                            child: Row(
                              children: [
                                Icon(
                                  isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(isActive ? 'Deactivate' : 'Activate'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: const [
                                Icon(Icons.copy_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Duplicate'),
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
                        child: const Icon(Icons.more_vert, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
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
                  items: [6, 12, 24, 48].map((items) {
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

  List<Map<String, dynamic>> _getFilteredBanners(List<Map<String, dynamic>> banners) {
    return banners.where((banner) {
      final title = (banner['title'] ?? '').toLowerCase();
      final description = (banner['description'] ?? '').toLowerCase();
      
      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery) ||
          description.contains(_searchQuery);

      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'active' && banner['isActive'] == true) ||
          (_statusFilter == 'inactive' && banner['isActive'] != true) ||
          (_statusFilter == 'scheduled' && _isBannerScheduled(banner)) ||
          (_statusFilter == 'expired' && _isBannerExpired(banner));

      final matchesType = _typeFilter == 'all' ||
          banner['type'] == _typeFilter;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  List<Map<String, dynamic>> _getPaginatedBanners(List<Map<String, dynamic>> banners) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, banners.length);
    return banners.sublist(startIndex, endIndex);
  }

  bool _isBannerExpired(Map<String, dynamic> banner) {
    if (banner['endDate'] == null) return false;
    try {
      final endDate = banner['endDate'].toDate() as DateTime;
      return DateTime.now().isAfter(endDate);
    } catch (e) {
      return false;
    }
  }

  bool _isBannerScheduled(Map<String, dynamic> banner) {
    if (banner['startDate'] == null) return false;
    try {
      final startDate = banner['startDate'].toDate() as DateTime;
      return DateTime.now().isBefore(startDate);
    } catch (e) {
      return false;
    }
  }

  String _getBannerStatus(Map<String, dynamic> banner) {
    if (_isBannerExpired(banner)) return 'expired';
    if (_isBannerScheduled(banner)) return 'scheduled';
    if (banner['isActive'] == true) return 'active';
    return 'inactive';
  }

  Color _getBannerStatusColor(Map<String, dynamic> banner) {
    final status = _getBannerStatus(banner);
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'scheduled':
        return AppColors.info;
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.textMedium;
    }
  }

  Color _getBannerTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'hero':
        return AppColors.primary;
      case 'promotional':
        return AppColors.secondary;
      case 'category':
        return AppColors.info;
      case 'product':
        return AppColors.success;
      default:
        return AppColors.textMedium;
    }
  }

  void _handleBannerAction(String action, Map<String, dynamic> banner, BannerProvider provider) {
    switch (action) {
      case 'view':
        _viewBanner(banner);
        break;
      case 'edit':
        _editBanner(banner);
        break;
      case 'toggle_status':
        final newStatus = !(banner['isActive'] ?? false);
        provider.updateBannerStatus(banner['id'], newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Banner activated' : 'Banner deactivated'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case 'duplicate':
        _duplicateBanner(banner);
        break;
      case 'delete':
        _deleteBanner(banner, provider);
        break;
    }
  }

  void _viewBanner(Map<String, dynamic> banner) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 800,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Banner Preview',
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
              
              // Banner Image
              if (banner['imageUrl'] != null)
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(banner['imageUrl']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Banner Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Title', banner['title'] ?? 'No title'),
                      _buildDetailRow('Description', banner['description'] ?? 'No description'),
                      _buildDetailRow('Type', banner['type'] ?? 'General'),
                      _buildDetailRow('Status', _getBannerStatus(banner)),
                      _buildDetailRow('Priority', banner['priority']?.toString() ?? 'None'),
                      _buildDetailRow('Click URL', banner['clickUrl'] ?? 'None'),
                      _buildDetailRow('Start Date', _formatDate(banner['startDate'])),
                      _buildDetailRow('End Date', _formatDate(banner['endDate'])),
                      _buildDetailRow('Created', _formatDate(banner['createdAt'])),
                    ],
                  ),
                ),
              ),
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Not set';
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _editBanner(Map<String, dynamic> banner) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit banner functionality coming soon')),
    );
  }

  void _duplicateBanner(Map<String, dynamic> banner) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate banner functionality coming soon')),
    );
  }

  void _deleteBanner(Map<String, dynamic> banner, BannerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: Text('Are you sure you want to delete "${banner['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.deleteBanner(banner['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Banner deleted successfully'),
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